import 'package:yomou/features/aozora/data/aozora_index_store.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_page_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';
import 'package:yomou/features/novels/domain/repositories/novel_catalog_repository.dart';

class AozoraNovelCatalogRepository implements NovelCatalogRepository {
  AozoraNovelCatalogRepository(this._indexStore);

  final AozoraIndexStore _indexStore;

  @override
  NovelSite get site => NovelSite.aozora;

  @override
  Future<PagedResult<NovelSummary>> fetchRankingPage(
    NovelRankingPageRequest request,
  ) {
    throw UnsupportedError('青空文庫にランキングはありません。');
  }

  @override
  Future<PagedResult<NovelSummary>> fetchSearchPage(
    NovelSearchRequest request,
  ) async {
    if (request.site != site) {
      throw ArgumentError.value(request.site, 'request.site', 'Unsupported site');
    }

    final normalizedRequest = request.copyWith(
      order: NovelSearchOrder.newest,
    );
    final page = await _indexStore.searchWorks(
      query: normalizedRequest.normalizedQuery,
      target: normalizedRequest.target,
      page: normalizedRequest.page,
      pageSize: normalizedRequest.pageSize,
    );

    return PagedResult<NovelSummary>(
      items: page.items
          .map(
            (work) => NovelSummary(
              site: NovelSite.aozora,
              id: work.id,
              title: work.subtitle == null || work.subtitle!.isEmpty
                  ? work.title
                  : '${work.title} ${work.subtitle}',
              author: work.author,
              genre: '青空文庫',
              isComplete: true,
              isShortStory: true,
            ),
          )
          .toList(growable: false),
      totalCount: page.totalCount,
      page: page.page,
      pageSize: page.pageSize,
    );
  }
}
