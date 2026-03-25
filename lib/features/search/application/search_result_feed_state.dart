import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';

class SearchResultFeedState {
  SearchResultFeedState({
    required List<NovelSummary> items,
    required this.hasMore,
    required this.nextPage,
    this.isLoadingMore = false,
    this.loadMoreErrorMessage,
  }) : items = List<NovelSummary>.unmodifiable(items);

  factory SearchResultFeedState.fromFirstPage(PagedResult<NovelSummary> page) {
    return SearchResultFeedState(
      items: page.items,
      hasMore: page.hasMore,
      nextPage: page.nextPage,
    );
  }

  final List<NovelSummary> items;
  final bool hasMore;
  final int nextPage;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;

  SearchResultFeedState copyWith({
    List<NovelSummary>? items,
    bool? hasMore,
    int? nextPage,
    bool? isLoadingMore,
    String? loadMoreErrorMessage,
    bool clearLoadMoreError = false,
  }) {
    return SearchResultFeedState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreErrorMessage:
          loadMoreErrorMessage ??
          (clearLoadMoreError ? null : this.loadMoreErrorMessage),
    );
  }
}
