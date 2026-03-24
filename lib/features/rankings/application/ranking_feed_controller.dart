import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_page_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/repositories/novel_catalog_repository.dart';
import 'package:yomou/features/novels/providers/novel_catalog_repository_provider.dart';
import 'package:yomou/features/rankings/application/ranking_feed_state.dart';

final rankingFeedControllerProvider =
    AsyncNotifierProvider.family<
      RankingFeedController,
      RankingFeedState,
      RankingFeedArgs
    >(RankingFeedController.new);

class RankingFeedArgs {
  const RankingFeedArgs({
    required this.site,
    required this.period,
    this.pageSize = 20,
  });

  final NovelSite site;
  final NovelRankingPeriod period;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RankingFeedArgs &&
            site == other.site &&
            period == other.period &&
            pageSize == other.pageSize;
  }

  @override
  int get hashCode => Object.hash(site, period, pageSize);
}

class RankingFeedController extends AsyncNotifier<RankingFeedState> {
  RankingFeedController(this.args);

  final RankingFeedArgs args;

  @override
  Future<RankingFeedState> build() async {
    final page = await _repository.fetchRankingPage(_requestFor(1));
    return RankingFeedState.fromFirstPage(page);
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
      final page = await _repository.fetchRankingPage(
        _requestFor(currentState.nextPage),
      );
      state = AsyncData(
        RankingFeedState(
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

  NovelRankingPageRequest _requestFor(int page) {
    return NovelRankingPageRequest(
      site: args.site,
      period: args.period,
      page: page,
      pageSize: args.pageSize,
    );
  }

  NovelCatalogRepository get _repository {
    return ref.read(novelCatalogRepositoryProvider(args.site));
  }
}
