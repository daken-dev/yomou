import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:yomou/core/network/dio_provider.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

final narouWebClientProvider = Provider<NarouWebClient>((ref) {
  return NarouWebClient(ref.watch(dioProvider));
});

const String narouBaseUrl = 'https://ncode.syosetu.com';
const String narouR18BaseUrl = 'https://novel18.syosetu.com';

String narouBaseUrlForSite(NovelSite site) {
  return switch (site) {
    NovelSite.narou => narouBaseUrl,
    NovelSite.narouR18 => narouR18BaseUrl,
    NovelSite.kakuyomu => throw UnsupportedError(
      'Kakuyomu does not use Narou web client',
    ),
    NovelSite.aozora => throw UnsupportedError(
      'Aozora does not use Narou web client',
    ),
  };
}

class NarouWebClient {
  NarouWebClient(this._dio);

  final Dio _dio;

  Future<NarouInfoPage> fetchInfoPage(
    String novelId, {
    NovelSite site = NovelSite.narou,
  }) async {
    final url = buildInfoUrl(novelId, site: site);
    final document = await _fetchDocument(url);
    return NarouInfoPage.fromDocument(url: url, document: document);
  }

  Future<NarouTocPage> fetchTocPage(
    String novelId, {
    NovelSite site = NovelSite.narou,
    int page = 1,
    String? inheritedChapterTitle,
    NarouInfoPage? shortStoryInfoPage,
  }) async {
    final url = buildTocUrl(novelId, page: page, site: site);
    final document = await _fetchDocument(url);
    final resolvedInheritedChapterTitle =
        inheritedChapterTitle ??
        (page > 1 ? await _findInheritedChapter(url) : null);
    final resolvedShortStoryInfoPage =
        NarouTocPage.looksLikeSingleEpisodeDocument(document)
        ? (shortStoryInfoPage ?? await fetchInfoPage(novelId, site: site))
        : null;
    return NarouTocPage.fromDocument(
      url: url,
      document: document,
      inheritedChapterTitle: resolvedInheritedChapterTitle,
      shortStoryInfoPage: resolvedShortStoryInfoPage,
    );
  }

  Future<NarouEpisodePage> fetchEpisodePage(
    String novelId,
    int episodeNo, {
    NovelSite site = NovelSite.narou,
    String? url,
  }) async {
    final resolvedUrl = url ?? buildEpisodeUrl(novelId, episodeNo, site: site);
    final document = await _fetchDocument(resolvedUrl);
    return NarouEpisodePage.fromDocument(url: resolvedUrl, document: document);
  }

  String buildInfoUrl(String novelId, {NovelSite site = NovelSite.narou}) {
    final baseUrl = narouBaseUrlForSite(site);
    return '$baseUrl/novelview/infotop/ncode/${novelId.toLowerCase()}/';
  }

  String buildTocUrl(
    String novelId, {
    NovelSite site = NovelSite.narou,
    int page = 1,
  }) {
    final baseUrl = narouBaseUrlForSite(site);
    final base = '$baseUrl/${novelId.toLowerCase()}/';
    if (page <= 1) {
      return base;
    }
    return '$base?p=$page';
  }

  String buildEpisodeUrl(
    String novelId,
    int episodeNo, {
    NovelSite site = NovelSite.narou,
  }) {
    final baseUrl = narouBaseUrlForSite(site);
    return '$baseUrl/${novelId.toLowerCase()}/$episodeNo/';
  }

  Future<Document> _fetchDocument(String url) async {
    final uri = Uri.parse(url);
    final response = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: _headersFor(uri),
      ),
    );

    final html = response.data;
    if (html == null || html.isEmpty) {
      throw const FormatException('Narou page returned an empty response.');
    }

    return html_parser.parse(html);
  }

  Map<String, Object> _headersFor(Uri uri) {
    final headers = <String, Object>{
      'User-Agent':
          'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'ja,en-US;q=0.9,en;q=0.8',
    };

    // novel18ドメインは年齢確認Cookieがないと403になることがある。
    if (uri.host == 'novel18.syosetu.com') {
      headers['Referer'] = 'https://novel18.syosetu.com/';
      headers['Cookie'] = 'over18=yes';
    }

    return headers;
  }

  Future<String?> _findInheritedChapter(String url) async {
    var previousUrl = buildPreviousPageUrl(url);
    while (previousUrl != null) {
      final document = await _fetchDocument(previousUrl);
      final eplist = document.querySelector('.p-eplist');
      if (eplist != null) {
        for (final child in eplist.children.reversed) {
          if (child.classes.contains('p-eplist__chapter-title')) {
            return elementText(child);
          }
        }
      }
      previousUrl = buildPreviousPageUrl(previousUrl);
    }
    return null;
  }
}

class NarouInfoPage {
  const NarouInfoPage({
    required this.url,
    required this.title,
    required this.authorUrl,
    required this.fields,
    required this.kasasagiUrl,
    required this.workUrl,
    required this.qrcodeUrl,
  });

  factory NarouInfoPage.fromDocument({
    required String url,
    required Document document,
  }) {
    final info = document.querySelector('.p-infotop-data');
    final fields = <String, String>{};
    if (info != null) {
      final titles = info.querySelectorAll('dt');
      final values = info.querySelectorAll('dd');
      final length = titles.length < values.length
          ? titles.length
          : values.length;
      for (var index = 0; index < length; index += 1) {
        final key = elementText(titles[index]) ?? '';
        final value = blockText(values[index]) ?? '';
        fields[key] = value;
      }
    }

    Element? authorLink;
    if (info != null) {
      for (final title in info.querySelectorAll('dt')) {
        final text = elementText(title);
        if (text != null && text.contains('作者名')) {
          authorLink = title.nextElementSibling?.querySelector('a');
          break;
        }
      }
    }

    final kasasagiLink = document.querySelector(
      '.p-infotop-kasasagi__analytics a',
    );
    final workLink = document.querySelector('.p-infotop-towork__button');
    final qrImage = document.querySelector('.p-infotop-towork__qr img');

    return NarouInfoPage(
      url: url,
      title: elementText(document.querySelector('.p-infotop__title, h1')),
      authorUrl: absoluteUrl(authorLink?.attributes['href']),
      fields: fields,
      kasasagiUrl: absoluteUrl(kasasagiLink?.attributes['href']),
      workUrl: absoluteUrl(workLink?.attributes['href']),
      qrcodeUrl: qrImage?.attributes['src'],
    );
  }

  final String url;
  final String? title;
  final String? authorUrl;
  final Map<String, String> fields;
  final String? kasasagiUrl;
  final String? workUrl;
  final String? qrcodeUrl;

  String? get authorName => fields['作者名'];

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'page_type': 'info',
      'url': url,
      'title': title,
      'author_url': authorUrl,
      'fields': fields,
      'kasasagi_url': kasasagiUrl,
      'work_url': workUrl,
      'qrcode_url': qrcodeUrl,
    };
  }
}

class NarouTocPage {
  const NarouTocPage({
    required this.url,
    required this.page,
    required this.title,
    required this.authorName,
    required this.authorUrl,
    required this.summary,
    required this.summaryHtml,
    required this.latestEpisodePublished,
    required this.lastPage,
    required this.lastPageUrl,
    required this.entries,
  });

  factory NarouTocPage.fromDocument({
    required String url,
    required Document document,
    String? inheritedChapterTitle,
    NarouInfoPage? shortStoryInfoPage,
  }) {
    final pageNumber = parsePageNumber(url);
    final authorLink = document.querySelector('.p-novel__author a');
    final summaryElement =
        document.querySelector('#novel_ex') ??
        document.querySelector('.p-novel__summary');
    final pagerLast = document.querySelector('.c-pager__item--last');
    final eplist = document.querySelector('.p-eplist');
    final hasBody = document.querySelector('.p-novel__body') != null;

    final entries = <NarouTocEntry>[];
    var insertedInheritedChapter = false;
    if (eplist != null) {
      for (final child in eplist.children) {
        final classes = child.classes;
        if (classes.contains('p-eplist__chapter-title')) {
          entries.add(
            NarouTocEntry.chapter(
              title: elementText(child),
              indexPage: pageNumber,
              inherited: false,
            ),
          );
          insertedInheritedChapter = true;
          continue;
        }

        if (!classes.contains('p-eplist__sublist')) {
          continue;
        }

        if (!insertedInheritedChapter && inheritedChapterTitle != null) {
          entries.add(
            NarouTocEntry.chapter(
              title: inheritedChapterTitle,
              indexPage: pageNumber,
              inherited: true,
            ),
          );
          insertedInheritedChapter = true;
        }

        entries.add(NarouTocEntry.episodeFromElement(child, url, pageNumber));
      }
    }

    if (entries.isEmpty && hasBody) {
      final title = elementText(document.querySelector('.p-novel__title'));
      entries.add(
        NarouTocEntry.episode(
          episodeNo: 1,
          title: title ?? shortStoryInfoPage?.title ?? '',
          url: url,
          indexPage: pageNumber,
          publishedAt: shortStoryInfoPage?.fields['掲載日'],
          revisedAt: shortStoryInfoPage?.fields['最終更新日'],
        ),
      );
    }

    return NarouTocPage(
      url: url,
      page: pageNumber,
      title: elementText(document.querySelector('.p-novel__title')),
      authorName: elementText(authorLink) ?? shortStoryInfoPage?.authorName,
      authorUrl:
          absoluteUrl(authorLink?.attributes['href']) ??
          shortStoryInfoPage?.authorUrl,
      summary: blockText(summaryElement) ?? shortStoryInfoPage?.fields['あらすじ'],
      summaryHtml: summaryElement?.innerHtml,
      latestEpisodePublished:
          elementText(document.querySelector('.p-novel__date-published')) ??
          shortStoryInfoPage?.fields['掲載日'],
      lastPage: parseLastPageNumber(document, url),
      lastPageUrl: absoluteUrl(pagerLast?.attributes['href'], url),
      entries: entries,
    );
  }

  static bool looksLikeSingleEpisodeDocument(Document document) {
    return document.querySelector('.p-eplist') == null &&
        document.querySelector('.p-novel__body') != null;
  }

  final String url;
  final int page;
  final String? title;
  final String? authorName;
  final String? authorUrl;
  final String? summary;
  final String? summaryHtml;
  final String? latestEpisodePublished;
  final int lastPage;
  final String? lastPageUrl;
  final List<NarouTocEntry> entries;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'page_type': 'toc',
      'url': url,
      'page': page,
      'title': title,
      'author': <String, Object?>{'name': authorName, 'url': authorUrl},
      'summary': summary,
      'summary_html': summaryHtml,
      'latest_episode_published': latestEpisodePublished,
      'last_page': lastPage,
      'last_page_url': lastPageUrl,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }
}

class NarouTocEntry {
  const NarouTocEntry._({
    required this.type,
    required this.title,
    required this.indexPage,
    required this.inherited,
    this.episodeNo,
    this.url,
    this.publishedAt,
    this.revisedAt,
  });

  factory NarouTocEntry.chapter({
    required String? title,
    required int indexPage,
    bool inherited = false,
  }) {
    return NarouTocEntry._(
      type: NarouTocEntryType.chapter,
      title: title,
      indexPage: indexPage,
      inherited: inherited,
    );
  }

  factory NarouTocEntry.episode({
    required int episodeNo,
    required String title,
    required String url,
    required int indexPage,
    String? publishedAt,
    String? revisedAt,
  }) {
    return NarouTocEntry._(
      type: NarouTocEntryType.episode,
      episodeNo: episodeNo,
      title: title,
      url: url,
      publishedAt: publishedAt,
      revisedAt: revisedAt,
      indexPage: indexPage,
      inherited: false,
    );
  }

  factory NarouTocEntry.episodeFromElement(
    Element element,
    String pageUrl,
    int pageNumber,
  ) {
    final subtitle = element.querySelector('.p-eplist__subtitle');
    final update = element.querySelector('.p-eplist__update');
    final href = subtitle?.attributes['href'];
    final episodeNo = extractEpisodeNumber(href);

    String? revisedAt;
    final revised = update?.querySelector('span');
    final revisedTitle = revised?.attributes['title'];
    if (revisedTitle != null) {
      revisedAt = cleanText(revisedTitle.replaceAll(' 改稿', ''));
    }

    return NarouTocEntry._(
      type: NarouTocEntryType.episode,
      episodeNo: episodeNo,
      title: blockText(subtitle),
      url: absoluteUrl(href, pageUrl),
      publishedAt: cleanText(firstTextNode(update)),
      revisedAt: revisedAt,
      indexPage: pageNumber,
      inherited: false,
    );
  }

  final NarouTocEntryType type;
  final int? episodeNo;
  final String? title;
  final String? url;
  final String? publishedAt;
  final String? revisedAt;
  final int indexPage;
  final bool inherited;

  bool get isEpisode => type == NarouTocEntryType.episode;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type == NarouTocEntryType.chapter ? 'chapter' : 'episode',
      'episode_no': episodeNo,
      'title': title,
      'url': url,
      'published_at': publishedAt,
      'revised_at': revisedAt,
      'inherited': type == NarouTocEntryType.chapter ? inherited : null,
      'index_page': indexPage,
    };
  }
}

enum NarouTocEntryType { chapter, episode }

class NarouEpisodePage {
  const NarouEpisodePage({
    required this.url,
    required this.novelTitle,
    required this.novelUrl,
    required this.authorName,
    required this.authorUrl,
    required this.sequence,
    required this.sequenceCurrent,
    required this.sequenceTotal,
    required this.title,
    required this.preface,
    required this.prefaceHtml,
    required this.body,
    required this.bodyHtml,
    required this.afterword,
    required this.afterwordHtml,
    required this.tocUrl,
    required this.prevUrl,
    required this.nextUrl,
  });

  factory NarouEpisodePage.fromDocument({
    required String url,
    required Document document,
  }) {
    final navigation = <String, String?>{
      'toc': null,
      'prev': null,
      'next': null,
    };
    for (final link in document.querySelectorAll(
      '.c-pager--center a.c-pager__item',
    )) {
      final label = elementText(link);
      final href = absoluteUrl(link.attributes['href'], url);
      if (label == '目次') {
        navigation['toc'] = href;
      } else if (label == '前へ') {
        navigation['prev'] = href;
      } else if (label == '次へ') {
        navigation['next'] = href;
      }
    }

    Element? announce;
    for (final candidate in document.querySelectorAll(
      '.c-announce-box .c-announce',
    )) {
      final links = candidate.querySelectorAll('a');
      if (links.length >= 2) {
        final href = links.first.attributes['href'] ?? '';
        if (href.startsWith('/')) {
          announce = candidate;
          break;
        }
      }
    }

    final announceLinks = announce?.querySelectorAll('a') ?? const <Element>[];
    final novelLink = announceLinks.isNotEmpty ? announceLinks[0] : null;
    final authorLink = announceLinks.length > 1 ? announceLinks[1] : null;
    final fallbackAuthorLink = document.querySelector('.p-novel__author a');

    final sections = findBodySections(document);
    final number = elementText(document.querySelector('.p-novel__number'));
    final pageTitle = elementText(document.querySelector('.p-novel__title'));
    final isSingleEpisode =
        number == null &&
        navigation['prev'] == null &&
        navigation['next'] == null &&
        sections.body != null;
    final resolvedSequence = number ?? (isSingleEpisode ? '1 / 1' : null);
    final sequenceMatch = RegExp(
      r'(\d+)\s*/\s*(\d+)',
    ).firstMatch(resolvedSequence ?? '');

    return NarouEpisodePage(
      url: url,
      novelTitle: elementText(novelLink) ?? pageTitle,
      novelUrl:
          absoluteUrl(novelLink?.attributes['href'], url) ??
          (isSingleEpisode ? url : null),
      authorName: elementText(authorLink ?? fallbackAuthorLink),
      authorUrl: absoluteUrl(
        (authorLink ?? fallbackAuthorLink)?.attributes['href'],
        url,
      ),
      sequence: resolvedSequence,
      sequenceCurrent: int.tryParse(sequenceMatch?.group(1) ?? ''),
      sequenceTotal: int.tryParse(sequenceMatch?.group(2) ?? ''),
      title: pageTitle,
      preface: blockText(sections.preface),
      prefaceHtml: sections.preface?.innerHtml,
      body: blockText(sections.body),
      bodyHtml: sections.body?.innerHtml,
      afterword: blockText(sections.afterword),
      afterwordHtml: sections.afterword?.innerHtml,
      tocUrl: navigation['toc'] ?? (isSingleEpisode ? url : null),
      prevUrl: navigation['prev'],
      nextUrl: navigation['next'],
    );
  }

  final String url;
  final String? novelTitle;
  final String? novelUrl;
  final String? authorName;
  final String? authorUrl;
  final String? sequence;
  final int? sequenceCurrent;
  final int? sequenceTotal;
  final String? title;
  final String? preface;
  final String? prefaceHtml;
  final String? body;
  final String? bodyHtml;
  final String? afterword;
  final String? afterwordHtml;
  final String? tocUrl;
  final String? prevUrl;
  final String? nextUrl;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'page_type': 'episode',
      'url': url,
      'novel_title': novelTitle,
      'novel_url': novelUrl,
      'author_name': authorName,
      'author_url': authorUrl,
      'sequence': sequence,
      'sequence_current': sequenceCurrent,
      'sequence_total': sequenceTotal,
      'title': title,
      'preface': preface,
      'preface_html': prefaceHtml,
      'body': body,
      'body_html': bodyHtml,
      'afterword': afterword,
      'afterword_html': afterwordHtml,
      'navigation': <String, Object?>{
        'toc_url': tocUrl,
        'prev_url': prevUrl,
        'next_url': nextUrl,
      },
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

class BodySections {
  const BodySections({this.preface, this.body, this.afterword});

  final Element? preface;
  final Element? body;
  final Element? afterword;
}

BodySections findBodySections(Document document) {
  final container = document.querySelector('.p-novel__body');
  if (container == null) {
    return const BodySections();
  }

  Element? preface;
  Element? body;
  Element? afterword;
  for (final child in container.children) {
    final classes = child.classes;
    if (!classes.contains('p-novel__text')) {
      continue;
    }
    if (classes.contains('p-novel__text--preface')) {
      preface = child;
      continue;
    }
    if (classes.contains('p-novel__text--afterword')) {
      afterword = child;
      continue;
    }
    body ??= child;
  }

  return BodySections(preface: preface, body: body, afterword: afterword);
}

String? cleanText(String? value) {
  if (value == null) {
    return null;
  }
  final text = value
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text.isEmpty ? null : text;
}

String? elementText(Element? element) {
  if (element == null) {
    return null;
  }
  return cleanText(element.text);
}

String? blockText(Element? element) {
  if (element == null) {
    return null;
  }

  final raw = element.text.replaceAll('\u00a0', ' ');
  final lines = raw
      .split('\n')
      .map((line) => line.replaceAll('\r', ''))
      .toList();
  while (lines.isNotEmpty && lines.first.trim().isEmpty) {
    lines.removeAt(0);
  }
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }

  final normalized = <String>[];
  var blankPending = false;
  for (final line in lines) {
    final trimmed = line.trimRight();
    if (trimmed.trim().isEmpty) {
      blankPending = true;
      continue;
    }
    if (blankPending && normalized.isNotEmpty) {
      normalized.add('');
    }
    normalized.add(trimmed.trimLeft());
    blankPending = false;
  }

  if (normalized.isEmpty) {
    return null;
  }
  return normalized.join('\n');
}

String? absoluteUrl(String? value, [String baseUrl = narouBaseUrl]) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return Uri.parse(baseUrl).resolve(value).toString();
}

int parsePageNumber(String url) {
  final page = Uri.parse(url).queryParameters['p'];
  return int.tryParse(page ?? '') ?? 1;
}

String? buildPreviousPageUrl(String url) {
  final uri = Uri.parse(url);
  final page = parsePageNumber(url);
  if (page <= 1) {
    return null;
  }

  final queryParameters = Map<String, String>.from(uri.queryParameters);
  if (page - 1 <= 1) {
    queryParameters.remove('p');
  } else {
    queryParameters['p'] = '${page - 1}';
  }

  return uri.replace(queryParameters: queryParameters).toString();
}

int parseLastPageNumber(Document document, String currentUrl) {
  final href = document
      .querySelector('.c-pager__item--last')
      ?.attributes['href'];
  if (href == null) {
    return parsePageNumber(currentUrl);
  }
  return parsePageNumber(absoluteUrl(href, currentUrl) ?? currentUrl);
}

int? extractEpisodeNumber(String? href) {
  if (href == null) {
    return null;
  }
  final match = RegExp(r'/(\d+)/?$').firstMatch(href);
  return int.tryParse(match?.group(1) ?? '');
}

String? firstTextNode(Element? element) {
  if (element == null) {
    return null;
  }
  for (final node in element.nodes) {
    final text = cleanText(node.text);
    if (text != null) {
      return text;
    }
  }
  return null;
}
