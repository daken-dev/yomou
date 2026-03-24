import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/cache/timed_cache.dart';
import 'package:yomou/features/narou/data/narou_api_client.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_page_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';
import 'package:yomou/features/novels/domain/repositories/novel_catalog_repository.dart';

final narouNovelCatalogRepositoryProvider = Provider<NovelCatalogRepository>((
  ref,
) {
  return NarouNovelCatalogRepository(ref.watch(narouApiClientProvider));
});

class NarouNovelCatalogRepository implements NovelCatalogRepository {
  NarouNovelCatalogRepository(
    this._apiClient, {
    Duration cacheDuration = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _cache = TimedCache<NovelRankingPageRequest, PagedResult<NovelSummary>>(
         ttl: cacheDuration,
         now: now,
       );

  final NarouApiClient _apiClient;
  final TimedCache<NovelRankingPageRequest, PagedResult<NovelSummary>> _cache;

  @override
  NovelSite get site => NovelSite.narou;

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

    final cached = _cache.get(request);
    if (cached != null) {
      return cached;
    }

    final response = await _apiClient.fetchRankingPage(
      period: request.period,
      page: request.page,
      pageSize: request.pageSize,
    );

    final result = PagedResult<NovelSummary>(
      items: response.items
          .map((record) => record.toNovelSummary())
          .toList(growable: false),
      totalCount: response.totalCount,
      page: response.page,
      pageSize: response.pageSize,
    );

    _cache.set(request, result);

    return result;
  }
}
