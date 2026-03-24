import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/features/narou/data/narou_novel_catalog_repository.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';
import 'package:yomou/features/rankings/application/ranking_feed_controller.dart';

import '../../../test_support/fake_novel_catalog_repository.dart';

void main() {
  test('loadNextPage appends items and stops at the end', () async {
    final repository = FakeNovelCatalogRepository(
      site: NovelSite.narou,
      onFetch: (request) {
        if (request.page == 1) {
          return PagedResult<NovelSummary>(
            items: const [
              NovelSummary(site: NovelSite.narou, id: 'N0001AA', title: '作品1'),
              NovelSummary(site: NovelSite.narou, id: 'N0002AA', title: '作品2'),
            ],
            totalCount: 3,
            page: 1,
            pageSize: request.pageSize,
          );
        }

        if (request.page == 2) {
          return PagedResult<NovelSummary>(
            items: const [
              NovelSummary(site: NovelSite.narou, id: 'N0003AA', title: '作品3'),
            ],
            totalCount: 3,
            page: 2,
            pageSize: request.pageSize,
          );
        }

        fail('unexpected page: ${request.page}');
      },
    );

    final container = ProviderContainer(
      overrides: [
        narouNovelCatalogRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    const args = RankingFeedArgs(
      site: NovelSite.narou,
      period: NovelRankingPeriod.daily,
      pageSize: 2,
    );

    final firstPage = await container.read(
      rankingFeedControllerProvider(args).future,
    );
    expect(firstPage.items.map((item) => item.title), ['作品1', '作品2']);
    expect(firstPage.hasMore, isTrue);

    await container
        .read(rankingFeedControllerProvider(args).notifier)
        .loadNextPage();

    final state = container
        .read(rankingFeedControllerProvider(args))
        .requireValue;
    expect(state.items.map((item) => item.title), ['作品1', '作品2', '作品3']);
    expect(state.hasMore, isFalse);
    expect(repository.requests.length, 2);

    await container
        .read(rankingFeedControllerProvider(args).notifier)
        .loadNextPage();

    expect(repository.requests.length, 2);
  });
}
