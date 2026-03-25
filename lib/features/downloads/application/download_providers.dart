import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/database/app_database.dart';
import 'package:yomou/features/downloads/application/download_scheduler.dart';
import 'package:yomou/features/downloads/data/download_store.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/downloads/domain/entities/download_status_snapshot.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() {
    unawaited(database.dispose());
  });
  return database;
});

final downloadStoreProvider = Provider<DownloadStore>((ref) {
  return DownloadStore(ref.watch(appDatabaseProvider));
});

final downloadSchedulerProvider = Provider<DownloadScheduler>((ref) {
  final scheduler = DownloadScheduler(
    ref.watch(downloadStoreProvider),
    ref.watch(narouWebClientProvider),
  );
  unawaited(scheduler.start());
  ref.onDispose(() {
    unawaited(scheduler.dispose());
  });
  return scheduler;
});

final downloadSchedulerBootstrapProvider = Provider<void>((ref) {
  ref.watch(downloadSchedulerProvider);
});

final downloadChangeTickProvider = StreamProvider<int>((ref) async* {
  var tick = 0;
  yield tick;

  await for (final _ in ref.watch(downloadStoreProvider).changes) {
    tick += 1;
    yield tick;
  }
});

final savedNovelsProvider = FutureProvider<List<SavedNovelOverview>>((
  ref,
) async {
  ref.watch(downloadChangeTickProvider);
  return ref.watch(downloadStoreProvider).listSavedNovels();
});

final savedNovelIdsProvider = FutureProvider.family<Set<String>, NovelSite>((
  ref,
  site,
) async {
  ref.watch(downloadChangeTickProvider);
  return ref.watch(downloadStoreProvider).listSavedNovelIds(site);
});

final downloadStatusProvider = FutureProvider<DownloadStatusSnapshot>((
  ref,
) async {
  ref.watch(downloadChangeTickProvider);
  return ref.watch(downloadStoreProvider).getStatusSnapshot();
});
