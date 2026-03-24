import 'package:yomou/features/novels/domain/entities/novel_ranking_page_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';
import 'package:yomou/features/novels/domain/repositories/novel_catalog_repository.dart';

typedef RankingPageCallback =
    PagedResult<NovelSummary> Function(NovelRankingPageRequest request);

class FakeNovelCatalogRepository implements NovelCatalogRepository {
  FakeNovelCatalogRepository({required this.site, required this.onFetch});

  @override
  final NovelSite site;

  final RankingPageCallback onFetch;
  final List<NovelRankingPageRequest> requests = <NovelRankingPageRequest>[];

  @override
  Future<PagedResult<NovelSummary>> fetchRankingPage(
    NovelRankingPageRequest request,
  ) async {
    requests.add(request);
    return onFetch(request);
  }
}
