import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:yomou/core/network/dio_provider.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';

final hamelnWebClientProvider = Provider<HamelnWebClient>((ref) {
  return HamelnWebClient(ref.watch(dioProvider));
});

final hamelnOriginalOptionsProvider =
    FutureProvider<List<HamelnOriginalOption>>((ref) async {
      return ref.watch(hamelnWebClientProvider).fetchOriginalOptions();
    });

const String hamelnBaseUrl = 'https://syosetu.org';

class HamelnWebClient {
  HamelnWebClient(this._dio);

  final Dio _dio;

  Future<List<HamelnOriginalOption>> fetchOriginalOptions() async {
    final document = await _fetchDocument(buildSearchUrl());
    final select = document.querySelector('select[name="gensaku"]');
    if (select == null) {
      throw const FormatException(
        'Hameln search page did not contain original options.',
      );
    }

    final options = _parseOptions(select.outerHtml)
        .where((option) => option.value.startsWith('原作：'))
        .map(
          (option) =>
              HamelnOriginalOption(value: option.value, label: option.label),
        )
        .toList(growable: false);
    return options;
  }

  Future<PagedResult<NovelSummary>> fetchSearchPage(
    NovelSearchRequest request,
  ) async {
    final url = buildSearchUrl(request: request);
    final document = await _fetchDocument(url);
    final works = document.querySelectorAll('div.section3');
    final items = works
        .map((section) => _summaryFromSearchSection(section, url))
        .whereType<NovelSummary>()
        .toList(growable: false);
    final paging = _parsePaging(document, url);
    final heading = _parseHeading(document);

    return PagedResult<NovelSummary>(
      items: items,
      totalCount: heading.totalCount ?? (paging.lastPage * request.pageSize),
      page: paging.page,
      pageSize: request.pageSize,
    );
  }

  Future<NarouInfoPage> fetchInfoPage(String novelId) async {
    final url = buildInfoUrl(novelId);
    final document = await _fetchDocument(url);
    final title = elementText(
      document.querySelector('table tr td span[style*="font-size:120%"]'),
    );
    final fields = <String, String>{};
    for (final table in document.querySelectorAll('table')) {
      for (final row in table.querySelectorAll('tr')) {
        final cells = row.querySelectorAll('td');
        if (cells.length < 2) {
          continue;
        }
        final key = elementText(cells[0]);
        final value = blockText(cells[1]);
        if (key == null || value == null) {
          continue;
        }
        fields[key] = value;
      }
    }

    Element? authorLink;
    for (final link in document.querySelectorAll('a[href]')) {
      final href = link.attributes['href'] ?? '';
      if (href.contains('/user/')) {
        authorLink = link;
        break;
      }
    }

    return NarouInfoPage(
      url: url,
      title: title,
      authorUrl: absoluteUrl(authorLink?.attributes['href'], url),
      fields: fields,
      kasasagiUrl: null,
      workUrl: buildWorkUrl(novelId),
      qrcodeUrl: null,
    );
  }

  Future<NarouTocPage> fetchTocPage(String novelId) async {
    final url = buildWorkUrl(novelId);
    final document = await _fetchDocument(url);
    final sections = document.querySelectorAll('#maind > div.ss');
    final infoSection = sections.isNotEmpty ? sections.first : null;
    final summarySection = sections.length > 1 ? sections[1] : null;
    final tocSection = sections.length > 2 ? sections[2] : null;
    final title = elementText(
      infoSection?.querySelector('span[itemprop="name"]'),
    );
    final authorLink = infoSection?.querySelector('span[itemprop="author"] a');
    final summary = blockText(summarySection);
    final entries = <NarouTocEntry>[];

    if (tocSection != null) {
      for (final row in tocSection.querySelectorAll('tr')) {
        final cells = row.querySelectorAll('td');
        if (cells.length < 2) {
          continue;
        }
        final episodeLink = cells[0].querySelector('a[href]');
        final episodeTitle = elementText(episodeLink);
        final episodeUrl = absoluteUrl(episodeLink?.attributes['href'], url);
        final episodeNo =
            int.tryParse(cells[0].querySelector('span[id]')?.id ?? '') ??
            _extractEpisodeNoFromHtmlUrl(episodeLink?.attributes['href']) ??
            (entries.length + 1);
        if (episodeTitle == null || episodeUrl == null) {
          continue;
        }
        final publishedAt = cleanText(_textExcludingChildren(cells[1]));
        final revisedAt = _parseRevisedAt(
          cells[1].querySelector('span[title]'),
        );
        entries.add(
          NarouTocEntry.episode(
            episodeNo: episodeNo,
            title: episodeTitle,
            url: episodeUrl,
            indexPage: 1,
            publishedAt: publishedAt,
            revisedAt: revisedAt,
          ),
        );
      }
    }

    return NarouTocPage(
      url: url,
      page: 1,
      title: title,
      authorName: elementText(authorLink),
      authorUrl: absoluteUrl(authorLink?.attributes['href'], url),
      summary: summary,
      summaryHtml: summarySection?.innerHtml,
      latestEpisodePublished: entries.isEmpty ? null : entries.last.publishedAt,
      lastPage: 1,
      lastPageUrl: url,
      entries: entries,
    );
  }

  Future<NarouEpisodePage> fetchEpisodePage(
    String novelId,
    int episodeNo, {
    String? url,
  }) async {
    final resolvedUrl = url ?? buildEpisodeUrl(novelId, episodeNo);
    final document = await _fetchDocument(resolvedUrl);
    final main = document.querySelector('#maind > div.ss');
    if (main == null) {
      throw const FormatException('Hameln episode page structure was invalid.');
    }

    final novelLink = main.querySelector('p a[href="./"], p a[href="."]');
    final authorLink = main.querySelector('p a[href*="/user/"]');
    final titleSpans = main.querySelectorAll('span[style*="font-size:120%"]');
    final sequenceText = elementText(
      main.querySelector('div[style*="font-size:80%"]'),
    );
    final sequenceMatch = RegExp(
      r'(\d+)\s*/\s*(\d+)',
    ).firstMatch(sequenceText ?? '');

    String? tocUrl;
    String? prevUrl;
    String? nextUrl;
    for (final link in document.querySelectorAll('.novelnavi a[href]')) {
      final label = elementText(link);
      final href = absoluteUrl(link.attributes['href'], resolvedUrl);
      if (label == '目 次') {
        tocUrl = href;
      } else if (label?.contains('前の話') == true) {
        prevUrl = href;
      } else if (label?.contains('次の話') == true) {
        nextUrl = href;
      }
    }

    return NarouEpisodePage(
      url: resolvedUrl,
      novelTitle: elementText(novelLink),
      novelUrl: absoluteUrl(novelLink?.attributes['href'], resolvedUrl),
      authorName: elementText(authorLink),
      authorUrl: absoluteUrl(authorLink?.attributes['href'], resolvedUrl),
      sequence: sequenceText,
      sequenceCurrent: int.tryParse(sequenceMatch?.group(1) ?? ''),
      sequenceTotal: int.tryParse(sequenceMatch?.group(2) ?? ''),
      title: titleSpans.length > 1 ? elementText(titleSpans.last) : null,
      preface: blockText(document.querySelector('#maegaki')),
      prefaceHtml: document.querySelector('#maegaki')?.innerHtml,
      body: blockText(document.querySelector('#honbun')),
      bodyHtml: document.querySelector('#honbun')?.innerHtml,
      afterword: blockText(document.querySelector('#atogaki')),
      afterwordHtml: document.querySelector('#atogaki')?.innerHtml,
      tocUrl: tocUrl,
      prevUrl: prevUrl,
      nextUrl: nextUrl,
    );
  }

  String buildSearchUrl({NovelSearchRequest? request}) {
    final req = request;
    final queryParameters = <String, String>{
      'mode': 'search',
      'type': _searchOrderValue(req?.order ?? NovelSearchOrder.newest),
      if (req != null && req.hasQuery) 'word': req.normalizedQuery,
      if (req?.original case final original? when original.trim().isNotEmpty)
        'gensaku': original.trim(),
      if (req != null && req.page > 1) 'page': '${req.page}',
    };
    return Uri.https('syosetu.org', '/search/', queryParameters).toString();
  }

  String buildInfoUrl(String novelId) {
    return Uri.https('syosetu.org', '/', <String, String>{
      'mode': 'ss_detail',
      'nid': novelId,
    }).toString();
  }

  String buildWorkUrl(String novelId) {
    return '$hamelnBaseUrl/novel/$novelId/';
  }

  String buildEpisodeUrl(String novelId, int episodeNo) {
    return '${buildWorkUrl(novelId)}$episodeNo.html';
  }

  Future<Document> _fetchDocument(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: const <String, Object>{
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'ja,en-US;q=0.9,en;q=0.8',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Upgrade-Insecure-Requests': '1',
        },
      ),
    );
    final html = response.data;
    if (html == null || html.isEmpty) {
      throw const FormatException('Hameln page returned an empty response.');
    }
    return html_parser.parse(html);
  }

  NovelSummary? _summaryFromSearchSection(Element section, String pageUrl) {
    final id = section.id.replaceFirst('nid_', '');
    if (id.isEmpty) {
      return null;
    }

    final titleLink = section.querySelector(
      ".blo_title_base a[href*='/novel/']",
    );
    final metaLinks = section.querySelectorAll('.blo_title_sak a');
    final original = metaLinks.isNotEmpty ? elementText(metaLinks[0]) : null;
    final setting = metaLinks.length > 1 ? elementText(metaLinks[1]) : null;
    final genre = metaLinks.length > 2 ? elementText(metaLinks[2]) : null;
    final authorLink = metaLinks.isNotEmpty ? metaLinks.last : null;
    final episodeBlock = section.querySelector('.blo_wasuu_base');
    final status = elementText(episodeBlock?.querySelector('span')) ?? '';
    final episodeCount = int.tryParse(
      (episodeBlock?.querySelector("a[href*='/novel/']")?.text ?? '')
          .replaceAll(RegExp(r'[^\d]'), ''),
    );
    final charCount = int.tryParse(
      (episodeBlock?.querySelector('div[title="総文字数"]')?.text ?? '').replaceAll(
        RegExp(r'[^\d]'),
        '',
      ),
    );
    final tags = section
        .querySelectorAll('div.all_keyword a[href]')
        .where((element) => !element.classes.contains('alert_color'))
        .map((element) => elementText(element))
        .whereType<String>()
        .toList(growable: false);
    final favoritesMatch = RegExp(r'お気に入り：([\d,]+)').firstMatch(section.text);
    final reviewsMatch = RegExp(r'感想：([\d,]+)').firstMatch(section.text);

    final genreLabel = <String>[
      if (original != null && original.isNotEmpty) original,
      if (setting != null && setting.isNotEmpty) setting,
      if (genre != null && genre.isNotEmpty) genre,
    ].join(' / ');

    return NovelSummary(
      site: NovelSite.hameln,
      id: id,
      title: elementText(titleLink) ?? id,
      author: elementText(authorLink) ?? '',
      story: _normalizeSummary(
        elementText(section.querySelector('.blo_inword')),
      ),
      genre: genreLabel,
      keyword: tags.join(' '),
      episodeCount: episodeCount ?? 0,
      characterCount: charCount ?? 0,
      totalPoints: 0,
      reviewCount: _parseInt(reviewsMatch?.group(1)) ?? 0,
      bookmarkCount: _parseInt(favoritesMatch?.group(1)) ?? 0,
      isComplete: status.contains('完結'),
      isShortStory: status.contains('短編'),
    );
  }

  _HamelnHeading _parseHeading(Document document) {
    final headingNode = document.querySelector(
      '.section.normal.autopagerize_page_element .heading h2',
    );
    final heading = cleanText(headingNode?.text);
    if (heading == null) {
      return const _HamelnHeading();
    }
    final match = RegExp(r'^(.*)\(([\d,]+)件\)$').firstMatch(heading);
    return _HamelnHeading(
      heading: heading,
      displayQuery: cleanText(match?.group(1)) ?? heading,
      totalCount: _parseInt(match?.group(2)),
    );
  }

  _HamelnPaging _parsePaging(Document document, String pageUrl) {
    final paging = document.querySelector('.paging');
    if (paging == null) {
      final page =
          int.tryParse(Uri.parse(pageUrl).queryParameters['page'] ?? '') ?? 1;
      return _HamelnPaging(page: page, lastPage: page);
    }

    var currentPage =
        int.tryParse(paging.querySelector('strong')?.text.trim() ?? '') ?? 1;
    var lastPage = currentPage;

    for (final link in paging.querySelectorAll('a[href]')) {
      final label = elementText(link);
      final pageNo = int.tryParse(label ?? '');
      if (pageNo != null && pageNo > lastPage) {
        lastPage = pageNo;
      }
    }

    return _HamelnPaging(page: currentPage, lastPage: lastPage);
  }

  String _searchOrderValue(NovelSearchOrder order) {
    return switch (order) {
      NovelSearchOrder.newest => '0',
      NovelSearchOrder.overallPoint => '28',
      NovelSearchOrder.dailyPoint => '29',
      NovelSearchOrder.weeklyPoint => '30',
      NovelSearchOrder.monthlyPoint => '31',
      NovelSearchOrder.quarterlyPoint => '32',
      NovelSearchOrder.yearlyPoint => '33',
    };
  }
}

class HamelnOriginalOption {
  const HamelnOriginalOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _ParsedOption {
  const _ParsedOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _HamelnHeading {
  const _HamelnHeading({this.heading, this.displayQuery, this.totalCount});

  final String? heading;
  final String? displayQuery;
  final int? totalCount;
}

class _HamelnPaging {
  const _HamelnPaging({required this.page, required this.lastPage});

  final int page;
  final int lastPage;
}

List<_ParsedOption> _parseOptions(String selectHtml) {
  final pattern = RegExp(
    '<option(?<attrs>[^>]*)value="(?<value>[^"]*)"[^>]*>(?<label>.*?)(?=<option|</select>|\\Z)',
    dotAll: true,
    caseSensitive: false,
  );
  return pattern
      .allMatches(selectHtml)
      .map((match) {
        return _ParsedOption(
          value: match.namedGroup('value') ?? '',
          label:
              cleanText(
                (match.namedGroup('label') ?? '').replaceAll(
                  RegExp(r'<[^>]+>'),
                  ' ',
                ),
              ) ??
              '',
        );
      })
      .where((option) => option.label.isNotEmpty)
      .toList(growable: false);
}

String? _textExcludingChildren(Element element) {
  final buffer = StringBuffer();
  for (final node in element.nodes) {
    if (node is Text) {
      buffer.write(node.text);
    }
  }
  return cleanText(buffer.toString());
}

String? _parseRevisedAt(Element? element) {
  final title = element?.attributes['title'];
  if (title == null || title.isEmpty) {
    return null;
  }
  return cleanText(title.replaceAll('改稿', '').trim());
}

String _normalizeSummary(String? text) {
  if (text == null || text.isEmpty) {
    return '';
  }
  return text.replaceFirst('【あらすじ】', '').replaceAll('▼', '\n').trim();
}

int? _extractEpisodeNoFromHtmlUrl(String? href) {
  final match = RegExp(r'/(\d+)\.html').firstMatch(href ?? '');
  return int.tryParse(match?.group(1) ?? '');
}

int? _parseInt(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final digits = value.replaceAll(RegExp(r'[^\d-]'), '');
  if (digits.isEmpty) {
    return null;
  }
  return int.tryParse(digits);
}
