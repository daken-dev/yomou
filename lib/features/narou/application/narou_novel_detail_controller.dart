import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

final narouNovelDetailControllerProvider =
    AsyncNotifierProvider.family<
      NarouNovelDetailController,
      NarouNovelDetailState,
      ({NovelSite site, String novelId})
    >(NarouNovelDetailController.new);

class NarouNovelDetailController extends AsyncNotifier<NarouNovelDetailState> {
  NarouNovelDetailController(this._args);

  final ({NovelSite site, String novelId}) _args;

  late final NovelSite _site;
  late final String _novelId;

  @override
  Future<NarouNovelDetailState> build() async {
    _site = _args.site;
    _novelId = _args.novelId;
    final infoFuture = _client.fetchInfoPage(_novelId, site: _site);
    final tocPage = await _client.fetchTocPage(_novelId, site: _site);
    final infoPage = await infoFuture;

    return NarouNovelDetailState(
      title: infoPage.title ?? tocPage.title ?? _novelId,
      authorName: infoPage.authorName ?? tocPage.authorName ?? '',
      summary: tocPage.summary ?? '',
      infoFields: infoPage.fields,
      items: _mapEntries(tocPage.entries),
      currentPage: tocPage.page,
      lastPage: tocPage.lastPage,
      lastChapterTitle: _lastChapterTitle(tocPage.entries),
    );
  }

  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncData(
      currentState.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );

    try {
      final tocPage = await _client.fetchTocPage(
        _novelId,
        site: _site,
        page: currentState.currentPage + 1,
        inheritedChapterTitle: currentState.lastChapterTitle,
      );

      state = AsyncData(
        currentState.copyWith(
          items: <NarouNovelDetailListItem>[
            ...currentState.items,
            ..._mapEntries(tocPage.entries),
          ],
          currentPage: tocPage.page,
          lastPage: tocPage.lastPage,
          lastChapterTitle:
              _lastChapterTitle(tocPage.entries) ??
              currentState.lastChapterTitle,
          isLoadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (error) {
      state = AsyncData(
        currentState.copyWith(
          isLoadingMore: false,
          loadMoreErrorMessage: error.toString(),
        ),
      );
    }
  }

  NarouWebClient get _client => ref.read(narouWebClientProvider);

  List<NarouNovelDetailListItem> _mapEntries(List<NarouTocEntry> entries) {
    return entries
        .map((entry) {
          return switch (entry.type) {
            NarouTocEntryType.chapter => NarouNovelDetailListItem.chapter(
              title: entry.title ?? '',
            ),
            NarouTocEntryType.episode => NarouNovelDetailListItem.episode(
              title: entry.title ?? '',
              episodeNo: entry.episodeNo,
              episodeUrl: entry.url,
            ),
          };
        })
        .toList(growable: false);
  }

  String? _lastChapterTitle(List<NarouTocEntry> entries) {
    for (final entry in entries.reversed) {
      if (entry.type == NarouTocEntryType.chapter && entry.title != null) {
        return entry.title;
      }
    }
    return null;
  }
}

class NarouNovelDetailState {
  const NarouNovelDetailState({
    required this.title,
    required this.authorName,
    required this.summary,
    required this.infoFields,
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.lastChapterTitle,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
  });

  final String title;
  final String authorName;
  final String summary;
  final Map<String, String> infoFields;
  final List<NarouNovelDetailListItem> items;
  final int currentPage;
  final int lastPage;
  final String? lastChapterTitle;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;

  bool get hasMore => currentPage < lastPage;

  NarouNovelDetailState copyWith({
    String? title,
    String? authorName,
    String? summary,
    Map<String, String>? infoFields,
    List<NarouNovelDetailListItem>? items,
    int? currentPage,
    int? lastPage,
    String? lastChapterTitle,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    bool clearLoadMoreError = false,
  }) {
    return NarouNovelDetailState(
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      summary: summary ?? this.summary,
      infoFields: infoFields ?? this.infoFields,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      lastChapterTitle: lastChapterTitle ?? this.lastChapterTitle,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreErrorMessage: clearLoadMoreError
          ? null
          : loadMoreErrorMessage ?? this.loadMoreErrorMessage,
    );
  }
}

class NarouNovelDetailListItem {
  const NarouNovelDetailListItem.chapter({required this.title})
    : type = NarouNovelDetailListItemType.chapter,
      episodeNo = null,
      episodeUrl = null;

  const NarouNovelDetailListItem.episode({
    required this.title,
    required this.episodeNo,
    required this.episodeUrl,
  }) : type = NarouNovelDetailListItemType.episode;

  final NarouNovelDetailListItemType type;
  final String title;
  final int? episodeNo;
  final String? episodeUrl;

  bool get isChapter => type == NarouNovelDetailListItemType.chapter;
}

enum NarouNovelDetailListItemType { chapter, episode }
