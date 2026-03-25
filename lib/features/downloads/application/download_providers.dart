import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/core/database/app_database.dart';
import 'package:yomou/features/downloads/application/download_scheduler.dart';
import 'package:yomou/features/downloads/data/download_store.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/downloads/domain/entities/download_job_overview.dart';
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

final savedNovelsProvider = StreamProvider<List<SavedNovelOverview>>((
  ref,
) async* {
  final store = ref.watch(downloadStoreProvider);
  var previous = await store.listSavedNovels();
  yield previous;

  await for (final _ in store.changes) {
    final current = await store.listSavedNovels();
    if (_savedNovelOverviewListEquals(previous, current)) {
      continue;
    }
    previous = current;
    yield current;
  }
});

typedef SavedNovelKey = ({NovelSite site, String novelId});

final savedNovelOverviewProvider =
    StreamProvider.family<SavedNovelOverview?, SavedNovelKey>((ref, key) async* {
      final store = ref.watch(downloadStoreProvider);

      var previous = await store.getSavedNovelOverview(key.site, key.novelId);
      yield previous;

      await for (final _ in store.changes) {
        final current = await store.getSavedNovelOverview(key.site, key.novelId);
        if (_savedNovelOverviewNullableEquals(previous, current)) {
          continue;
        }
        previous = current;
        yield current;
      }
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

final downloadJobCountsProvider = FutureProvider<DownloadJobCounts>((
  ref,
) async {
  ref.watch(downloadChangeTickProvider);
  return ref.watch(downloadStoreProvider).getJobCounts();
});

final recentDownloadJobsProvider = FutureProvider<List<DownloadJobOverview>>((
  ref,
) async {
  ref.watch(downloadChangeTickProvider);
  return ref.watch(downloadStoreProvider).listRecentJobs();
});

bool _savedNovelOverviewListEquals(
  List<SavedNovelOverview> left,
  List<SavedNovelOverview> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (!_savedNovelOverviewEquals(left[index], right[index])) {
      return false;
    }
  }
  return true;
}

bool _savedNovelOverviewEquals(
  SavedNovelOverview left,
  SavedNovelOverview right,
) {
  return left.site == right.site &&
      left.id == right.id &&
      left.title == right.title &&
      left.state == right.state &&
      left.totalEpisodes == right.totalEpisodes &&
      left.downloadedEpisodes == right.downloadedEpisodes &&
      left.activeQueuedJobs == right.activeQueuedJobs &&
      left.activeRunningJobs == right.activeRunningJobs &&
      left.remainingEpisodes == right.remainingEpisodes &&
      left.resumeEpisodeNo == right.resumeEpisodeNo &&
      left.resumeEpisodeUrl == right.resumeEpisodeUrl &&
      left.resumePageNumber == right.resumePageNumber &&
      left.resumePageCount == right.resumePageCount &&
      left.createdAt == right.createdAt &&
      left.updatedAt == right.updatedAt &&
      left.lastError == right.lastError &&
      left.lockReason == right.lockReason &&
      left.nextRefreshAt == right.nextRefreshAt &&
      left.lastCheckedAt == right.lastCheckedAt &&
      left.lastSyncedAt == right.lastSyncedAt;
}

bool _savedNovelOverviewNullableEquals(
  SavedNovelOverview? left,
  SavedNovelOverview? right,
) {
  if (left == null || right == null) {
    return left == right;
  }
  return _savedNovelOverviewEquals(left, right);
}
