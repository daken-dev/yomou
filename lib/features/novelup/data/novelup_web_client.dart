import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:yomou/core/network/dio_provider.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';

final novelupWebClientProvider = Provider<NovelupWebClient>((ref) {
  return NovelupWebClient(ref.watch(dioProvider));
});

const String novelupBaseUrl = 'https://novelup.plus';

class NovelupWebClient {
  NovelupWebClient(this._dio);

  final Dio _dio;

  Future<PagedResult<NovelSummary>> fetchSearchPage(
    NovelSearchRequest request,
  ) async {
    final url = buildSearchUrl(request);
    final document = await _fetchDocument(url);
    final items = document
        .querySelectorAll('ul.searchResultList li.one_set .story_card')
        .map(_summaryFromStoryCard)
        .whereType<NovelSummary>()
        .toList(growable: false);
    final totalCount = _parseScaledNumber(
      elementText(document.querySelector('.searchResultHeader .searchCount')),
    );

    return PagedResult<NovelSummary>(
      items: items,
      totalCount: totalCount ?? _estimatedTotalCount(items.length, request),
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  Future<PagedResult<NovelSummary>> fetchRankingPage(
    NovelRankingPeriod period, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = buildRankingUrl(period, page: page);
    final document = await _fetchDocument(url);
    final items = document
        .querySelectorAll(
          '#infinite-scroll-container > li.infinite-scroll-item .story_card',
        )
        .map(_summaryFromStoryCard)
        .whereType<NovelSummary>()
        .toList(growable: false);
    final hasNext =
        document.querySelector('.infinite-scroll-more[href]') != null;

    return PagedResult<NovelSummary>(
      items: items,
      totalCount: hasNext ? (page * pageSize) + 1 : ((page - 1) * pageSize) + items.length,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<NarouInfoPage> fetchInfoPage(String novelId) async {
    final tocPage = await fetchTocPage(novelId);
    final episodeCount = tocPage.entries.where((entry) => entry.isEpisode).length;
    final fields = <String, String>{
      if (tocPage.summary case final summary? when summary.isNotEmpty)
        'あらすじ': summary,
      if (tocPage.authorName case final author? when author.isNotEmpty) '作者名': author,
      if (tocPage.genreLabel case final genre? when genre.isNotEmpty) 'ジャンル': genre,
      if (tocPage.lengthTypeLabel case final length? when length.isNotEmpty) '長さ': length,
      if (tocPage.serialStatusLabel case final status? when status.isNotEmpty) '連載状態': status,
      if (episodeCount > 0) '総エピソード数': '$episodeCount',
      ...tocPage.metaFields,
    };

    return NarouInfoPage(
      url: tocPage.url,
      title: tocPage.title,
      authorUrl: tocPage.authorUrl,
      fields: fields,
      kasasagiUrl: null,
      workUrl: tocPage.url,
      qrcodeUrl: null,
    );
  }

  Future<NovelupTocPage> fetchTocPage(String novelId) async {
    final url = buildWorkUrl(novelId);
    final document = await _fetchDocument(url);
    final authorLink =
        document.querySelector('.storyAuthor[href]') ??
        document.querySelector('.storyAuthor a[href]') ??
        document.querySelector('.storyIndexHeader a[href*="/user/"]');
    final stateLamp = document
        .querySelectorAll('.state_lamp > *')
        .map(elementText)
        .whereType<String>()
        .toList(growable: false);
    final metaFields = _parseMetaTable(document);
    final entries = _parseEntries(document, url);

    return NovelupTocPage(
      url: url,
      page: 1,
      title: elementText(document.querySelector('.storyTitle')),
      authorName: elementText(authorLink),
      authorUrl: absoluteUrl(authorLink?.attributes['href'], url),
      summary: blockText(document.querySelector('.novel_synopsis')),
      summaryHtml: document.querySelector('.novel_synopsis')?.innerHtml,
      latestEpisodePublished: _latestPublishedAt(entries),
      lastPage: 1,
      lastPageUrl: url,
      entries: entries,
      genreLabel: stateLamp.isNotEmpty ? stateLamp[0] : null,
      lengthTypeLabel: stateLamp.length >= 2 ? stateLamp[1] : null,
      serialStatusLabel: stateLamp.length >= 3 ? stateLamp[2] : null,
      metaFields: metaFields,
    );
  }

  Future<NarouEpisodePage> fetchEpisodePage(
    String novelId,
    int episodeNo, {
    String? url,
  }) async {
    final tocPage = await fetchTocPage(novelId);
    final episodeEntry = tocPage.entries.firstWhere(
      (entry) => entry.isEpisode && entry.episodeNo == episodeNo,
      orElse: () => throw StateError('ノベルアップ+の話数 $episodeNo が見つかりません。'),
    );
    final resolvedUrl = url ?? episodeEntry.url;
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      throw StateError('ノベルアップ+のエピソードURLを解決できません。');
    }

    final document = await _fetchDocument(resolvedUrl);
    final canonicalUrl =
        document.querySelector('link[rel="canonical"]')?.attributes['href'] ??
        resolvedUrl;
    final body = document.querySelector('#js-scroll-area .content');
    final foreword = document.querySelector('.novel_foreword');
    final afterword = document.querySelector('.novel_afterword');

    String? tocUrl;
    String? prevUrl;
    String? nextUrl;
    for (final link in document.querySelectorAll('.move_set a[href]')) {
      final label = elementText(link);
      final href = absoluteUrl(link.attributes['href'], canonicalUrl);
      if (label == '目次') {
        tocUrl = href;
      } else if (label == '前へ') {
        prevUrl = href;
      } else if (label == '次へ') {
        nextUrl = href;
      }
    }

    return NarouEpisodePage(
      url: canonicalUrl,
      novelTitle:
          elementText(document.querySelector('.episodeHeader .storyTitle')) ??
          tocPage.title,
      novelUrl: tocPage.url,
      authorName: tocPage.authorName,
      authorUrl: tocPage.authorUrl,
      sequence: '$episodeNo / ${tocPage.episodeCount}',
      sequenceCurrent: episodeNo,
      sequenceTotal: tocPage.episodeCount,
      title: elementText(document.querySelector('h1')),
      preface: blockText(foreword),
      prefaceHtml: foreword?.innerHtml,
      body: blockText(body),
      bodyHtml: body?.innerHtml,
      afterword: blockText(afterword),
      afterwordHtml: afterword?.innerHtml,
      tocUrl: tocUrl ?? tocPage.url,
      prevUrl: prevUrl,
      nextUrl: nextUrl,
    );
  }

  String buildSearchUrl(NovelSearchRequest request) {
    final queryParameters = <String, String>{
      if (request.hasQuery) 'q': request.normalizedQuery,
      if (request.genreCode case final genreCode?) 'genre[$genreCode]': '1',
      'sort': _searchOrderValue(request.order),
      if (request.page > 1) 'p': '${request.page}',
    };
    return Uri.https('novelup.plus', '/search', queryParameters).toString();
  }

  String buildRankingUrl(NovelRankingPeriod period, {int page = 1}) {
    final uri = Uri.parse('$novelupBaseUrl/ranking/all/${_rankingPeriodPath(period)}');
    if (page <= 1) {
      return uri.toString();
    }
    return uri.replace(queryParameters: <String, String>{'p': '$page'}).toString();
  }

  String buildWorkUrl(String novelId) => '$novelupBaseUrl/story/$novelId';

  Future<Document> _fetchDocument(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: const <String, Object>{
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'ja,en-US;q=0.9,en;q=0.8',
        },
      ),
    );
    final html = response.data;
    if (html == null || html.isEmpty) {
      throw const FormatException('NovelUp page returned an empty response.');
    }
    return html_parser.parse(html);
  }

  NovelSummary? _summaryFromStoryCard(Element card) {
    final titleLink = card.querySelector('.story_name a[href*="/story/"]');
    final workUrl = absoluteUrl(titleLink?.attributes['href'], novelupBaseUrl);
    final storyId = _extractStoryId(workUrl);
    if (storyId == null) {
      return null;
    }

    final tags = card
        .querySelectorAll('.story_tag a[href]')
        .map(elementText)
        .whereType<String>()
        .toList(growable: false);
    final lengthType = elementText(card.querySelector('.story_short')) ?? '';
    final statusText = card
        .querySelectorAll('.story_icons i.ic.story')
        .expand((icon) => icon.classes)
        .join(' ');

    return NovelSummary(
      site: NovelSite.novelup,
      id: storyId,
      title: elementText(titleLink) ?? storyId,
      author: elementText(card.querySelector('.story_author_name a')) ?? '',
      story:
          elementText(card.querySelector('.story_introduction')) ??
          elementText(card.querySelector('.story_comment')) ??
          '',
      genre: elementText(card.querySelector('.story_genre')) ?? '',
      keyword: tags.join(' '),
      episodeCount: _parseScaledNumber(
            elementText(card.querySelector('.story_episode_count')),
          ) ??
          0,
      characterCount: _parseScaledNumber(
            elementText(card.querySelector('.story_length')),
          ) ??
          0,
      totalPoints: _parseScaledNumber(
            elementText(card.querySelector('.story_point span')),
          ) ??
          0,
      bookmarkCount: _parseScaledNumber(
            elementText(card.querySelector('.count_good span')),
          ) ??
          0,
      reviewCount: 0,
      isComplete: statusText.contains('complete') || statusText.contains('finish'),
      isShortStory: lengthType.contains('短編'),
    );
  }

  List<NarouTocEntry> _parseEntries(Document document, String pageUrl) {
    final entries = <NarouTocEntry>[];
    for (final item in document.querySelectorAll('.episodeList .episodeListItem')) {
      final classes = item.classes.toSet();
      if (classes.contains('chapter')) {
        entries.add(
          NarouTocEntry.chapter(title: elementText(item), indexPage: 1),
        );
        continue;
      }

      final titleLink = item.querySelector('a.episodeTitle[href]');
      final episodeUrl = absoluteUrl(titleLink?.attributes['href'], pageUrl);
      final title = elementText(titleLink);
      final episodeNo = _parseInt(titleLink?.attributes['data-number']) ?? _extractSequentialEpisodeNo(entries);
      if (episodeUrl == null || title == null) {
        continue;
      }

      final metaTexts = item
          .querySelectorAll('.episodeDate p, .episodeDate a.commentLink')
          .map(elementText)
          .whereType<String>()
          .toList(growable: false);
      entries.add(
        NarouTocEntry.episode(
          episodeNo: episodeNo,
          title: title,
          url: episodeUrl,
          indexPage: 1,
          publishedAt: metaTexts.isNotEmpty ? metaTexts[0] : null,
        ),
      );
    }
    return entries;
  }

  Map<String, String> _parseMetaTable(Document document) {
    const metaKeyMap = <String, String>{
      '初掲載日': '初掲載日',
      '最終更新日': '最終更新日',
      '完結日': '完結日',
      '文字数': '文字数',
      '読了目安時間': '読了目安時間',
      '総エピソード数': '総エピソード数',
      'ブックマーク登録': 'ブックマーク登録',
      'コメント': 'コメント',
      'スタンプ': 'スタンプ',
      'ビビッと': 'ビビッと',
      'いいね': 'いいね',
      '応援ポイント': '応援ポイント',
      'ノベラポイント': 'ノベラポイント',
      '応援レビュー': '応援レビュー',
      '誤字報告': '誤字報告',
    };

    final fields = <String, String>{};
    for (final row in document.querySelectorAll('table.storyMeta tr')) {
      final key = elementText(row.querySelector('th'));
      final value = cleanText(row.querySelector('td')?.text);
      if (key == null || value == null) {
        continue;
      }
      fields[metaKeyMap[key] ?? key] = value;
    }
    return fields;
  }

  int _estimatedTotalCount(int count, NovelSearchRequest request) {
    if (count >= request.pageSize) {
      return (request.page * request.pageSize) + 1;
    }
    return ((request.page - 1) * request.pageSize) + count;
  }

  String? _latestPublishedAt(List<NarouTocEntry> entries) {
    for (final entry in entries.reversed) {
      if (entry.isEpisode && entry.publishedAt != null) {
        return entry.publishedAt;
      }
    }
    return null;
  }

  int _extractSequentialEpisodeNo(List<NarouTocEntry> entries) {
    var count = 0;
    for (final entry in entries) {
      if (entry.isEpisode) {
        count += 1;
      }
    }
    return count + 1;
  }

  String _rankingPeriodPath(NovelRankingPeriod period) {
    return switch (period) {
      NovelRankingPeriod.daily => 'day',
      NovelRankingPeriod.weekly => 'week',
      NovelRankingPeriod.monthly => 'month',
      NovelRankingPeriod.yearly => 'year',
      NovelRankingPeriod.overall => 'total',
      NovelRankingPeriod.quarterly => 'month',
    };
  }

  String _searchOrderValue(NovelSearchOrder order) {
    return switch (order) {
      NovelSearchOrder.newest => '2',
      NovelSearchOrder.updated => '1',
      NovelSearchOrder.dailyPoint => '4',
      NovelSearchOrder.overallPoint => '8',
      NovelSearchOrder.weeklyPoint => '4',
      NovelSearchOrder.monthlyPoint => '8',
      NovelSearchOrder.quarterlyPoint => '8',
      NovelSearchOrder.yearlyPoint => '8',
    };
  }
}

class NovelupTocPage extends NarouTocPage {
  const NovelupTocPage({
    required super.url,
    required super.page,
    required super.title,
    required super.authorName,
    required super.authorUrl,
    required super.summary,
    required super.summaryHtml,
    required super.latestEpisodePublished,
    required super.lastPage,
    required super.lastPageUrl,
    required super.entries,
    required this.genreLabel,
    required this.lengthTypeLabel,
    required this.serialStatusLabel,
    required this.metaFields,
  });

  final String? genreLabel;
  final String? lengthTypeLabel;
  final String? serialStatusLabel;
  final Map<String, String> metaFields;

  int get episodeCount => entries.where((entry) => entry.isEpisode).length;

  String? findChapterTitleForEpisode(int episodeNo) {
    String? currentChapterTitle;
    for (final entry in entries) {
      if (!entry.isEpisode) {
        currentChapterTitle = entry.title;
        continue;
      }
      if (entry.episodeNo == episodeNo) {
        return currentChapterTitle;
      }
    }
    return null;
  }
}

int? _parseInt(String? value) {
  if (value == null) {
    return null;
  }
  final digits = value.replaceAll(RegExp(r'[^\d-]'), '');
  if (digits.isEmpty) {
    return null;
  }
  return int.tryParse(digits);
}

int? _parseScaledNumber(String? value) {
  if (value == null) {
    return null;
  }
  final text = value.replaceAll(',', '').trim().toUpperCase();
  final match = RegExp(r'^(\d+(?:\.\d+)?)([KM]?)$').firstMatch(text);
  if (match == null) {
    return _parseInt(text);
  }

  final base = double.parse(match.group(1)!);
  final scaled = switch (match.group(2)) {
    'K' => base * 1000,
    'M' => base * 1000000,
    _ => base,
  };
  return scaled.toInt();
}

String? _extractStoryId(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  }
  final match = RegExp(r'/story/(\d+)').firstMatch(Uri.parse(url).path);
  return match?.group(1);
}
