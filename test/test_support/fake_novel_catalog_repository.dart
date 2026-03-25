import 'package:yomou/features/novels/domain/entities/novel_ranking_page_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';
import 'package:yomou/features/novels/domain/repositories/novel_catalog_repository.dart';

typedef RankingPageCallback =
    PagedResult<NovelSummary> Function(NovelRankingPageRequest request);
typedef SearchPageCallback =
    PagedResult<NovelSummary> Function(NovelSearchRequest request);

class FakeNovelCatalogRepository implements NovelCatalogRepository {
  FakeNovelCatalogRepository({
    required this.site,
    RankingPageCallback? onFetch,
    SearchPageCallback? onFetchSearch,
  }) : onFetch = onFetch ?? _defaultRankingFetch,
       onFetchSearch = onFetchSearch ?? _defaultSearchFetch;

  @override
  final NovelSite site;

  final RankingPageCallback onFetch;
  final SearchPageCallback onFetchSearch;
  final List<NovelRankingPageRequest> requests = <NovelRankingPageRequest>[];
  final List<NovelSearchRequest> searchRequests = <NovelSearchRequest>[];

  @override
  Future<PagedResult<NovelSummary>> fetchRankingPage(
    NovelRankingPageRequest request,
  ) async {
    requests.add(request);
    return onFetch(request);
  }

  @override
  Future<PagedResult<NovelSummary>> fetchSearchPage(
    NovelSearchRequest request,
  ) async {
    searchRequests.add(request);
    return onFetchSearch(request);
  }

  static PagedResult<NovelSummary> _defaultRankingFetch(
    NovelRankingPageRequest request,
  ) {
    throw UnimplementedError('Ranking fetch was not configured for this test.');
  }

  static PagedResult<NovelSummary> _defaultSearchFetch(
    NovelSearchRequest request,
  ) {
    throw UnimplementedError('Search fetch was not configured for this test.');
  }
}
