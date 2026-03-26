import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:yomou/core/network/dio_provider.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/kakuyomu/domain/entities/kakuyomu_genre.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';

final kakuyomuWebClientProvider = Provider<KakuyomuWebClient>((ref) {
  return KakuyomuWebClient(ref.watch(dioProvider));
});

const String kakuyomuBaseUrl = 'https://kakuyomu.jp';

class KakuyomuWebClient {
  KakuyomuWebClient(this._dio);

  final Dio _dio;

  Future<PagedResult<NovelSummary>> fetchSearchPage(
    NovelSearchRequest request,
  ) async {
    final url = buildSearchUrl(request);
    final document = await _fetchDocument(url);
    final apollo = _parseApolloState(document);
    final root = _resolveMap(apollo['ROOT_QUERY']);
    final connectionKey = root.keys.cast<String?>().firstWhere(
      (key) => key != null && key.startsWith('searchWorks('),
      orElse: () => null,
    );
    if (connectionKey == null) {
      throw const FormatException(
        'Kakuyomu search page did not contain searchWorks data.',
      );
    }

    final connection = _resolveMap(root[connectionKey]);
    final items = _resolveList(connection['nodes'])
        .map((value) => _workSummaryFromValue(apollo, value))
        .whereType<NovelSummary>()
        .toList(growable: false);

    return PagedResult<NovelSummary>(
      items: items,
      totalCount: _asInt(connection['totalCount']) ?? items.length,
      page: request.page,
      pageSize: request.pageSize,
    );
  }

  Future<NarouInfoPage> fetchInfoPage(String novelId) async {
    final tocPage = await fetchTocPage(novelId);
    final episodeCount = tocPage.entries
        .where((entry) => entry.isEpisode)
        .length;
    final fields = <String, String>{
      if (tocPage.summary case final summary? when summary.isNotEmpty)
        '紹介': summary,
      if (tocPage.genreLabel case final genre when genre.isNotEmpty)
        'ジャンル': genre,
      if (tocPage.serialStatusLabel case final status when status.isNotEmpty)
        '連載状態': status,
      if (tocPage.totalCharacterCount > 0)
        '文字数': '${tocPage.totalCharacterCount}字',
      if (episodeCount > 0) '公開話数': '$episodeCount話',
      if (tocPage.totalReviewPoint > 0) '★': '${tocPage.totalReviewPoint}',
      if (tocPage.totalFollowers > 0) 'フォロワー': '${tocPage.totalFollowers}',
      if (tocPage.reviewCount > 0) 'レビュー': '${tocPage.reviewCount}',
      if (tocPage.tags.isNotEmpty) 'タグ': tocPage.tags.join(' '),
      if (tocPage.publishedAt case final publishedAt?
          when publishedAt.isNotEmpty)
        '公開日': publishedAt,
      if (tocPage.latestEpisodePublished case final updatedAt?
          when updatedAt.isNotEmpty)
        '最終更新日': updatedAt,
      if (tocPage.contentWarnings.isNotEmpty)
        '注意': tocPage.contentWarnings.join(' / '),
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

  Future<KakuyomuTocPage> fetchTocPage(String novelId) async {
    final url = buildWorkUrl(novelId);
    final document = await _fetchDocument(url);
    final apollo = _parseApolloState(document);
    final root = _resolveMap(apollo['ROOT_QUERY']);
    final workKey = root.keys.cast<String?>().firstWhere(
      (key) => key != null && key.startsWith('work('),
      orElse: () => null,
    );
    if (workKey == null) {
      throw const FormatException(
        'Kakuyomu work page did not contain work data.',
      );
    }

    final work = _resolveRef(apollo, root[workKey]);
    if (work == null) {
      throw const FormatException(
        'Kakuyomu work page contained an invalid work reference.',
      );
    }

    final author = _resolveRef(apollo, work['author']);
    final authorId = _refId(work['author']) ?? _asString(author?['name']);
    final entries = <NarouTocEntry>[];
    var episodeNo = 0;

    for (final tocRef in _resolveList(work['tableOfContents'])) {
      final tocChapter = _resolveRef(apollo, tocRef);
      if (tocChapter == null) {
        continue;
      }

      final chapter = _resolveRef(apollo, tocChapter['chapter']);
      final chapterTitle = _asString(chapter?['title']);
      if (chapterTitle != null && chapterTitle.isNotEmpty) {
        entries.add(NarouTocEntry.chapter(title: chapterTitle, indexPage: 1));
      }

      for (final episodeRef in _resolveList(tocChapter['episodeUnions'])) {
        final episode = _resolveRef(apollo, episodeRef);
        if (episode == null) {
          continue;
        }
        final episodeId = _asString(episode['id']);
        final title = _asString(episode['title']);
        if (episodeId == null || title == null) {
          continue;
        }
        episodeNo += 1;
        entries.add(
          NarouTocEntry.episode(
            episodeNo: episodeNo,
            title: title,
            url: buildEpisodeUrl(novelId, episodeId),
            indexPage: 1,
            publishedAt: _asString(episode['publishedAt']),
          ),
        );
      }
    }

    final firstEpisode = _resolveRef(apollo, work['firstPublicEpisodeUnion']);
    return KakuyomuTocPage(
      url: url,
      page: 1,
      title: _asString(work['title']),
      authorName:
          _asString(author?['activityName']) ?? _asString(author?['name']),
      authorUrl: authorId == null ? null : '$kakuyomuBaseUrl/users/$authorId',
      summary:
          _asString(work['introduction']) ?? _asString(work['catchphrase']),
      latestEpisodePublished: _asString(work['lastEpisodePublishedAt']),
      entries: entries,
      genreLabel: KakuyomuGenre.labelOfSlug(_asString(work['genre'])),
      serialStatusLabel: _serialStatusLabel(_asString(work['serialStatus'])),
      totalReviewPoint: _asInt(work['totalReviewPoint']) ?? 0,
      totalFollowers: _asInt(work['totalFollowers']) ?? 0,
      reviewCount: _asInt(work['reviewCount']) ?? 0,
      totalCharacterCount: _asInt(work['totalCharacterCount']) ?? 0,
      tags: _resolveStringList(work['tagLabels']),
      contentWarnings: _contentWarnings(work),
      publishedAt: _asString(work['publishedAt']),
      firstEpisodeUrl: firstEpisode == null
          ? null
          : buildEpisodeUrl(novelId, _asString(firstEpisode['id']) ?? ''),
    );
  }

  Future<NarouEpisodePage> fetchEpisodePage(
    String novelId,
    int episodeNo, {
    String? url,
  }) async {
    final resolvedUrl = url ?? buildEpisodeUrl(novelId, '$episodeNo');
    final document = await _fetchDocument(resolvedUrl);
    final canonicalUrl =
        document.querySelector('link[rel="canonical"]')?.attributes['href'] ??
        resolvedUrl;
    final workId = extractWorkId(canonicalUrl) ?? novelId;
    final episodeId = extractEpisodeId(canonicalUrl);
    final tocPage = await fetchTocPage(workId);
    final episodeMeta = tocPage.findEpisodeById(episodeId);
    final chapterMeta = tocPage.findChapterForEpisodeId(episodeId);
    final header = document.querySelector('#contentMain-header');
    final authorLink =
        header?.querySelector('#contentMain-header-author a') ??
        header?.querySelector('#contentMain-header-author');
    final body = document.querySelector('.widget-episodeBody');
    final prevLink = document.querySelector('#contentMain-readPrevEpisode');
    final nextLink = document.querySelector('#contentMain-readNextEpisode');
    final relPrev = document.querySelector('link[rel="prev"]');
    final relNext = document.querySelector('link[rel="next"]');
    final current = episodeMeta?.episodeNo;
    final total = tocPage.entries.where((entry) => entry.isEpisode).length;

    return NarouEpisodePage(
      url: canonicalUrl,
      novelTitle:
          elementText(header?.querySelector('#contentMain-header-workTitle')) ??
          tocPage.title,
      novelUrl: buildWorkUrl(workId),
      authorName: elementText(authorLink) ?? tocPage.authorName,
      authorUrl:
          absoluteUrl(authorLink?.attributes['href'], canonicalUrl) ??
          tocPage.authorUrl,
      sequence: current == null ? null : '$current / $total',
      sequenceCurrent: current,
      sequenceTotal: total == 0 ? null : total,
      title:
          elementText(document.querySelector('.widget-episodeTitle')) ??
          chapterMeta?.title,
      preface: null,
      prefaceHtml: null,
      body: _kakuyomuBlockText(body),
      bodyHtml: body?.innerHtml,
      afterword: null,
      afterwordHtml: null,
      tocUrl: buildWorkUrl(workId),
      prevUrl:
          absoluteUrl(prevLink?.attributes['href'], canonicalUrl) ??
          absoluteUrl(relPrev?.attributes['href'], canonicalUrl),
      nextUrl:
          absoluteUrl(nextLink?.attributes['href'], canonicalUrl) ??
          absoluteUrl(relNext?.attributes['href'], canonicalUrl),
    );
  }

  String buildSearchUrl(NovelSearchRequest request) {
    final queryParameters = <String, String>{
      if (request.hasQuery) 'q': request.normalizedQuery,
      'order': _searchOrderValue(request.order),
      if (request.genreCode case final genreCode?)
        if (KakuyomuGenre.fromCode(genreCode) case final genre?)
          'genre_name': genre.slug,
      if (request.page > 1) 'page': '${request.page}',
    };
    return Uri.https('kakuyomu.jp', '/search', queryParameters).toString();
  }

  String buildWorkUrl(String workId) {
    return '$kakuyomuBaseUrl/works/$workId';
  }

  String buildEpisodeUrl(String workId, String episodeId) {
    return '$kakuyomuBaseUrl/works/$workId/episodes/$episodeId';
  }

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
      throw const FormatException('Kakuyomu page returned an empty response.');
    }
    return html_parser.parse(html);
  }

  Map<String, dynamic> _parseApolloState(Document document) {
    final script = document.querySelector('#__NEXT_DATA__');
    final text = script?.text;
    if (text == null || text.isEmpty) {
      throw const FormatException(
        'Kakuyomu page did not contain __NEXT_DATA__.',
      );
    }
    final json = jsonDecode(text);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Kakuyomu __NEXT_DATA__ was malformed.');
    }
    final props = _resolveMap(json['props']);
    final pageProps = _resolveMap(props['pageProps']);
    return _resolveMap(pageProps['__APOLLO_STATE__']);
  }

  NovelSummary? _workSummaryFromValue(
    Map<String, dynamic> apollo,
    Object? value,
  ) {
    final work = _resolveRef(apollo, value);
    if (work == null) {
      return null;
    }
    final author = _resolveRef(apollo, work['author']);
    final episodeCount = _asInt(work['publicEpisodeCount']) ?? 0;
    final title = _asString(work['title']);
    final id = _asString(work['id']);
    if (title == null || id == null) {
      return null;
    }
    return NovelSummary(
      site: NovelSite.kakuyomu,
      id: id,
      title: title,
      author:
          _asString(author?['activityName']) ??
          _asString(author?['name']) ??
          '',
      story:
          _asString(work['introduction']) ??
          _asString(work['catchphrase']) ??
          '',
      genre: KakuyomuGenre.labelOfSlug(_asString(work['genre'])),
      keyword: _resolveStringList(work['tagLabels']).join(' '),
      episodeCount: episodeCount,
      characterCount: _asInt(work['totalCharacterCount']) ?? 0,
      totalPoints: _asInt(work['totalReviewPoint']) ?? 0,
      reviewCount: _asInt(work['reviewCount']) ?? 0,
      bookmarkCount: _asInt(work['totalFollowers']) ?? 0,
      isComplete: _isCompleted(_asString(work['serialStatus'])),
      isShortStory: episodeCount <= 1,
    );
  }

  String _searchOrderValue(NovelSearchOrder order) {
    return switch (order) {
      NovelSearchOrder.newest => 'last_episode_published_at',
      NovelSearchOrder.weeklyPoint => 'weekly_ranking',
      NovelSearchOrder.overallPoint => 'total_ranking',
      _ => 'last_episode_published_at',
    };
  }

  bool _isCompleted(String? value) {
    return switch ((value ?? '').toLowerCase()) {
      'completed' => true,
      _ => false,
    };
  }

  String _serialStatusLabel(String? value) {
    return _isCompleted(value) ? '完結済' : '連載中';
  }

  List<String> _contentWarnings(Map<String, dynamic> work) {
    final warnings = <String>[];
    if (work['isCruel'] == true) {
      warnings.add('残酷描写あり');
    }
    if (work['isViolent'] == true) {
      warnings.add('暴力描写あり');
    }
    if (work['isSexual'] == true) {
      warnings.add('性描写あり');
    }
    return warnings;
  }

  Map<String, dynamic> _resolveMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<Object?> _resolveList(Object? value) {
    if (value is List) {
      return value.cast<Object?>();
    }
    return const <Object?>[];
  }

  Map<String, dynamic>? _resolveRef(
    Map<String, dynamic> apollo,
    Object? value,
  ) {
    final ref = _refId(value);
    if (ref == null) {
      return null;
    }
    return _resolveMap(apollo[ref]);
  }

  String? _refId(Object? value) {
    if (value is Map) {
      final ref = value['__ref'];
      if (ref is String && ref.isNotEmpty) {
        return ref;
      }
    }
    return null;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String? _asString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num) {
      return '$value';
    }
    return null;
  }

  List<String> _resolveStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class KakuyomuTocPage extends NarouTocPage {
  KakuyomuTocPage({
    required super.url,
    required super.page,
    required super.title,
    required super.authorName,
    required super.authorUrl,
    required super.summary,
    required super.latestEpisodePublished,
    required super.entries,
    required this.genreLabel,
    required this.serialStatusLabel,
    required this.totalReviewPoint,
    required this.totalFollowers,
    required this.reviewCount,
    required this.totalCharacterCount,
    required this.tags,
    required this.contentWarnings,
    required this.publishedAt,
    required this.firstEpisodeUrl,
  }) : super(summaryHtml: null, lastPage: 1, lastPageUrl: null);

  final String genreLabel;
  final String serialStatusLabel;
  final int totalReviewPoint;
  final int totalFollowers;
  final int reviewCount;
  final int totalCharacterCount;
  final List<String> tags;
  final List<String> contentWarnings;
  final String? publishedAt;
  final String? firstEpisodeUrl;

  NarouTocEntry? findEpisodeById(String? episodeId) {
    if (episodeId == null) {
      return null;
    }
    for (final entry in entries) {
      if (!entry.isEpisode) {
        continue;
      }
      final url = entry.url;
      if (url != null && extractEpisodeId(url) == episodeId) {
        return entry;
      }
    }
    return null;
  }

  NarouTocEntry? findChapterForEpisodeId(String? episodeId) {
    if (episodeId == null) {
      return null;
    }
    NarouTocEntry? currentChapter;
    for (final entry in entries) {
      if (!entry.isEpisode) {
        currentChapter = entry;
        continue;
      }
      final url = entry.url;
      if (url != null && extractEpisodeId(url) == episodeId) {
        return currentChapter;
      }
    }
    return currentChapter;
  }
}

String? extractWorkId(String url) {
  final match = RegExp(r'/works/([0-9]+)').firstMatch(Uri.parse(url).path);
  return match?.group(1);
}

String? extractEpisodeId(String url) {
  final match = RegExp(r'/episodes/([0-9]+)').firstMatch(Uri.parse(url).path);
  return match?.group(1);
}

String? _kakuyomuBlockText(Element? element) {
  if (element == null) {
    return null;
  }
  final paragraphs = <String>[];
  var blankPending = false;
  for (final child in element.children) {
    final classes = child.classes;
    if (classes.contains('blank')) {
      blankPending = true;
      continue;
    }
    final text = child.text.replaceAll('\u00a0', ' ').trimRight();
    if (text.trim().isEmpty) {
      blankPending = true;
      continue;
    }
    if (blankPending && paragraphs.isNotEmpty) {
      paragraphs.add('');
    }
    paragraphs.add(text);
    blankPending = false;
  }
  if (paragraphs.isEmpty) {
    final fallback = element.text.trim();
    return fallback.isEmpty ? null : fallback;
  }
  return paragraphs.join('\n');
}
