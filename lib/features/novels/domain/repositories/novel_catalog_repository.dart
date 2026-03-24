import 'package:yomou/features/novels/domain/entities/novel_ranking_page_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';

abstract interface class NovelCatalogRepository {
  NovelSite get site;

  Future<PagedResult<NovelSummary>> fetchRankingPage(
    NovelRankingPageRequest request,
  );
}
