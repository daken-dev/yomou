import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/cache/timed_cache.dart';
import 'package:yomou/features/kakuyomu/data/kakuyomu_web_client.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_page_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';
import 'package:yomou/features/novels/domain/repositories/novel_catalog_repository.dart';

final kakuyomuNovelCatalogRepositoryProvider = Provider<NovelCatalogRepository>(
  (ref) {
    return KakuyomuNovelCatalogRepository(ref.watch(kakuyomuWebClientProvider));
  },
);

class KakuyomuNovelCatalogRepository implements NovelCatalogRepository {
  KakuyomuNovelCatalogRepository(
    this._client, {
    Duration cacheDuration = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _searchCache = TimedCache<NovelSearchRequest, PagedResult<NovelSummary>>(
         ttl: cacheDuration,
         now: now,
       );

  final KakuyomuWebClient _client;
  final TimedCache<NovelSearchRequest, PagedResult<NovelSummary>> _searchCache;

  @override
  NovelSite get site => NovelSite.kakuyomu;

  @override
  Future<PagedResult<NovelSummary>> fetchRankingPage(
    NovelRankingPageRequest request,
  ) async {
    if (request.site != site) {
      throw ArgumentError.value(
        request.site,
        'request.site',
        'Unsupported site',
      );
    }

    return fetchSearchPage(
      NovelSearchRequest(
        site: site,
        order: _searchOrderFor(request.period),
        page: request.page,
        pageSize: request.pageSize,
      ),
    );
  }

  @override
  Future<PagedResult<NovelSummary>> fetchSearchPage(
    NovelSearchRequest request,
  ) async {
    if (request.site != site) {
      throw ArgumentError.value(
        request.site,
        'request.site',
        'Unsupported site',
      );
    }

    final cached = _searchCache.get(request);
    if (cached != null) {
      return cached;
    }

    final result = await _client.fetchSearchPage(request);
    _searchCache.set(request, result);
    return result;
  }

  NovelSearchOrder _searchOrderFor(NovelRankingPeriod period) {
    return switch (period) {
      NovelRankingPeriod.overall => NovelSearchOrder.overallPoint,
      NovelRankingPeriod.weekly => NovelSearchOrder.weeklyPoint,
      NovelRankingPeriod.daily => NovelSearchOrder.weeklyPoint,
      NovelRankingPeriod.monthly => NovelSearchOrder.weeklyPoint,
      NovelRankingPeriod.quarterly => NovelSearchOrder.weeklyPoint,
      NovelRankingPeriod.yearly => NovelSearchOrder.weeklyPoint,
    };
  }
}
