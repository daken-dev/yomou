import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/core/database/app_database.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

void main() {
  test('savedNovelIdsProvider refreshes after saving a novel', () async {
    final database = AppDatabase(pathProvider: () async => ':memory:');
    addTearDown(database.dispose);

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final provider = savedNovelIdsProvider(NovelSite.narou);
    final subscription = container.listen<AsyncValue<Set<String>>>(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _waitForValue(subscription, <String>{});

    await container
        .read(downloadStoreProvider)
        .saveNovel(
          const NovelSummary(
            site: NovelSite.narou,
            id: 'N0001AA',
            title: '作品1',
          ),
        );

    await _waitForValue(subscription, {'N0001AA'});
  });
}

Future<void> _waitForValue(
  ProviderSubscription<AsyncValue<Set<String>>> subscription,
  Set<String> expected,
) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    final current = subscription.read();
    if (current.hasValue && current.requireValue.length == expected.length) {
      final actual = current.requireValue;
      if (actual.containsAll(expected)) {
        return;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  final current = subscription.read();
  expect(current.hasValue ? current.requireValue : null, expected);
}
