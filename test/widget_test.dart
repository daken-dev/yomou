import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/app/app.dart';
import 'package:yomou/features/narou/data/narou_novel_catalog_repository.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/domain/entities/paged_result.dart';

import 'test_support/fake_novel_catalog_repository.dart';

void main() {
  testWidgets('drawer navigates to Narou daily ranking', (tester) async {
    final repository = FakeNovelCatalogRepository(
      site: NovelSite.narou,
      onFetch: (request) {
        expect(request.period, NovelRankingPeriod.daily);

        return PagedResult<NovelSummary>(
          items: const [
            NovelSummary(site: NovelSite.narou, id: 'N0001AA', title: 'ランキング1'),
            NovelSummary(site: NovelSite.narou, id: 'N0002AA', title: 'ランキング2'),
          ],
          totalCount: 2,
          page: request.page,
          pageSize: request.pageSize,
        );
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          narouNovelCatalogRepositoryProvider.overrideWithValue(repository),
        ],
        child: const YomouApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('保存済み作品'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('なろう'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ランキング'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('なろう 日刊ランキング'), findsOneWidget);
    expect(find.text('ランキング1'), findsOneWidget);
    expect(find.text('ランキング2'), findsOneWidget);
  });
}
