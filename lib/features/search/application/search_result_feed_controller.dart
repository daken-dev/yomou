import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/repositories/novel_catalog_repository.dart';
import 'package:yomou/features/novels/providers/novel_catalog_repository_provider.dart';
import 'package:yomou/features/search/application/search_result_feed_state.dart';

final searchResultFeedControllerProvider =
    AsyncNotifierProvider.family<
      SearchResultFeedController,
      SearchResultFeedState,
      NovelSearchRequest
    >(SearchResultFeedController.new);

class SearchResultFeedController extends AsyncNotifier<SearchResultFeedState> {
  SearchResultFeedController(this.request);

  final NovelSearchRequest request;

  @override
  Future<SearchResultFeedState> build() async {
    final page = await _repository.fetchSearchPage(request.copyWith(page: 1));
    return SearchResultFeedState.fromFirstPage(page);
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
      final page = await _repository.fetchSearchPage(
        request.copyWith(page: currentState.nextPage),
      );
      state = AsyncData(
        SearchResultFeedState(
          items: [...currentState.items, ...page.items],
          hasMore: page.hasMore,
          nextPage: page.nextPage,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        currentState.copyWith(
          isLoadingMore: false,
          loadMoreErrorMessage: error.toString(),
          clearLoadMoreError: true,
        ),
      );
    }
  }

  NovelCatalogRepository get _repository {
    return ref.read(novelCatalogRepositoryProvider(request.site));
  }
}
