import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/cache/timed_cache.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_page_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';
import 'package:yomou/features/novels/domain/repositories/novel_catalog_repository.dart';
import 'package:yomou/features/novelup/data/novelup_web_client.dart';

final novelupNovelCatalogRepositoryProvider = Provider<NovelCatalogRepository>((
  ref,
) {
  return NovelupNovelCatalogRepository(ref.watch(novelupWebClientProvider));
});

class NovelupNovelCatalogRepository implements NovelCatalogRepository {
  NovelupNovelCatalogRepository(
    this._client, {
    Duration cacheDuration = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _rankingCache =
           TimedCache<NovelRankingPageRequest, PagedResult<NovelSummary>>(
             ttl: cacheDuration,
             now: now,
           ),
       _searchCache = TimedCache<NovelSearchRequest, PagedResult<NovelSummary>>(
         ttl: cacheDuration,
         now: now,
       );

  final NovelupWebClient _client;
  final TimedCache<NovelRankingPageRequest, PagedResult<NovelSummary>>
  _rankingCache;
  final TimedCache<NovelSearchRequest, PagedResult<NovelSummary>> _searchCache;

  @override
  NovelSite get site => NovelSite.novelup;

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

    final cached = _rankingCache.get(request);
    if (cached != null) {
      return cached;
    }

    final result = await _client.fetchRankingPage(
      _normalizePeriod(request.period),
      page: request.page,
      pageSize: request.pageSize,
    );
    _rankingCache.set(request, result);
    return result;
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

    final normalized = request.copyWith(order: _normalizeOrder(request.order));
    final result = await _client.fetchSearchPage(normalized);
    _searchCache.set(request, result);
    return result;
  }

  NovelRankingPeriod _normalizePeriod(NovelRankingPeriod period) {
    return switch (period) {
      NovelRankingPeriod.quarterly => NovelRankingPeriod.monthly,
      _ => period,
    };
  }

  NovelSearchOrder _normalizeOrder(NovelSearchOrder order) {
    return switch (order) {
      NovelSearchOrder.weeklyPoint => NovelSearchOrder.dailyPoint,
      NovelSearchOrder.monthlyPoint => NovelSearchOrder.overallPoint,
      NovelSearchOrder.quarterlyPoint => NovelSearchOrder.overallPoint,
      NovelSearchOrder.yearlyPoint => NovelSearchOrder.overallPoint,
      _ => order,
    };
  }
}
