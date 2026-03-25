import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/core/database/app_database.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
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

  test('savedNovelIdsProvider refreshes after removing a novel', () async {
    final database = AppDatabase(pathProvider: () async => ':memory:');
    addTearDown(database.dispose);

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    const novel = NovelSummary(
      site: NovelSite.narou,
      id: 'N0001AA',
      title: '作品1',
    );
    await container.read(downloadStoreProvider).saveNovel(novel);

    final provider = savedNovelIdsProvider(NovelSite.narou);
    final subscription = container.listen<AsyncValue<Set<String>>>(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _waitForValue(subscription, {'N0001AA'});

    await container
        .read(downloadStoreProvider)
        .removeNovel(novel.site, novel.id);

    await _waitForValue(subscription, <String>{});
  });

  test('savedNovelOverviewProvider refreshes after save and remove', () async {
    final database = AppDatabase(pathProvider: () async => ':memory:');
    addTearDown(database.dispose);

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final provider = savedNovelOverviewProvider((
      site: NovelSite.narou,
      novelId: 'N0001AA',
    ));
    final subscription = container.listen<AsyncValue<SavedNovelOverview?>>(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _waitForOverview(subscription, null);

    await container
        .read(downloadStoreProvider)
        .saveNovel(
          const NovelSummary(
            site: NovelSite.narou,
            id: 'N0001AA',
            title: '作品1',
          ),
        );

    await _waitForOverview(subscription, '作品1');

    await container
        .read(downloadStoreProvider)
        .removeNovel(NovelSite.narou, 'N0001AA');

    await _waitForOverview(subscription, null);
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

Future<void> _waitForOverview(
  ProviderSubscription<AsyncValue<SavedNovelOverview?>> subscription,
  String? expectedTitle,
) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    final current = subscription.read();
    if (!current.hasValue) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      continue;
    }

    final value = current.requireValue;
    if (expectedTitle == null && value == null) {
      return;
    }
    if (value?.title == expectedTitle) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  final current = subscription.read();
  expect(current.hasValue ? current.requireValue?.title : null, expectedTitle);
}
