import 'dart:async';

import 'package:yomou/features/downloads/data/download_store.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/downloads/domain/entities/download_job_overview.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

class DownloadScheduler {
  DownloadScheduler(this._store, this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const int maxConcurrentScrapes = 2;
  static const int manualSyncPriority = 5000;
  static const int manualRefreshAllPriority = 4500;
  static const int scheduledSyncPriority = 2500;
  static const Duration refreshInterval = Duration(hours: 1);
  static const Duration refreshCheckInterval = Duration(minutes: 5);

  final DownloadStore _store;
  final NarouWebClient _client;
  final DateTime Function() _now;

  StreamSubscription<void>? _changesSubscription;
  Timer? _refreshTimer;
  var _started = false;
  var _pumpScheduled = false;
  var _runningJobs = 0;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    await _store.requeueRunningJobs();
    await _store.enqueueDueRefreshes(
      scheduledAt: _now(),
      priority: scheduledSyncPriority,
    );

    _changesSubscription = _store.changes.listen((_) {
      _schedulePump();
    });
    _refreshTimer = Timer.periodic(refreshCheckInterval, (_) {
      unawaited(
        _store.enqueueDueRefreshes(
          scheduledAt: _now(),
          priority: scheduledSyncPriority,
        ),
      );
    });
    _schedulePump();
  }

  Future<void> dispose() async {
    _started = false;
    _refreshTimer?.cancel();
    await _changesSubscription?.cancel();
  }

  Future<void> saveNovel(NovelSummary novel) async {
    await _store.saveNovel(novel);
    await _store.enqueueSyncNovel(
      site: novel.site,
      novelId: novel.id,
      priority: manualSyncPriority,
    );
    _schedulePump();
  }

  Future<void> refreshNovel(NovelSite site, String novelId) async {
    await _store.enqueueSyncNovel(
      site: site,
      novelId: novelId,
      priority: manualSyncPriority,
      force: true,
    );
    _schedulePump();
  }

  Future<void> refreshAll() async {
    await _store.enqueueRefreshForAllSaved(
      priority: manualRefreshAllPriority,
      force: true,
    );
    _schedulePump();
  }

  void _schedulePump() {
    if (!_started || _pumpScheduled) {
      return;
    }
    _pumpScheduled = true;
    Future<void>.microtask(() async {
      _pumpScheduled = false;
      await _pump();
    });
  }

  Future<void> _pump() async {
    while (_started && _runningJobs < maxConcurrentScrapes) {
      final job = await _store.claimNextJob();
      if (job == null) {
        return;
      }

      _runningJobs += 1;
      unawaited(
        _runJob(job).whenComplete(() {
          _runningJobs -= 1;
          _schedulePump();
        }),
      );
    }
  }

  Future<void> _runJob(DownloadJobRecord job) async {
    try {
      switch (job.type) {
        case DownloadJobType.syncNovel:
          await _runSyncNovel(job);
        case DownloadJobType.downloadEpisode:
          await _runEpisodeDownload(job);
      }

      await _store.completeJob(job);
    } on UpdateLockedException catch (error) {
      await _store.recordNovelError(job.site, job.novelId, error.message);
      await _store.failJob(
        job,
        error.message,
        retryDelay: const Duration(seconds: 0),
        retryable: false,
      );
    } catch (error) {
      final message = error.toString();
      await _store.recordNovelError(job.site, job.novelId, message);
      await _store.failJob(
        job,
        message,
        retryDelay: Duration(seconds: 30 * job.attempts),
        retryable: true,
      );
    }
  }

  Future<void> _runSyncNovel(DownloadJobRecord job) async {
    switch (job.site) {
      case NovelSite.narou:
        final infoPage = await _client.fetchInfoPage(job.novelId);
        final firstTocPage = await _client.fetchTocPage(
          job.novelId,
          shortStoryInfoPage: infoPage,
        );
        final tocPages = <NarouTocPage>[firstTocPage];
        var lastChapterTitle = _lastChapterTitle(firstTocPage.entries);
        for (var page = 2; page <= firstTocPage.lastPage; page += 1) {
          final tocPage = await _client.fetchTocPage(
            job.novelId,
            page: page,
            inheritedChapterTitle: lastChapterTitle,
          );
          tocPages.add(tocPage);
          lastChapterTitle =
              _lastChapterTitle(tocPage.entries) ?? lastChapterTitle;
        }

        final result = await _store.applyNovelSync(
          site: job.site,
          novelId: job.novelId,
          fallbackTitle: firstTocPage.title ?? infoPage.title ?? job.novelId,
          infoPage: infoPage,
          tocPages: tocPages,
          force: job.force,
          refreshInterval: refreshInterval,
        );

        if (result.isLocked) {
          throw UpdateLockedException(result.lockReason ?? '更新ロック');
        }

        await _store.enqueueEpisodeDownloads(
          job.site,
          job.novelId,
          result.downloadPlans,
        );
    }
  }

  Future<void> _runEpisodeDownload(DownloadJobRecord job) async {
    final episodeNo = job.episodeNo;
    if (episodeNo == null) {
      throw StateError('Episode job missing episode number.');
    }

    switch (job.site) {
      case NovelSite.narou:
        final episodeUrl = await _store.episodeUrlFor(
          job.site,
          job.novelId,
          episodeNo,
        );
        final page = await _client.fetchEpisodePage(
          job.novelId,
          episodeNo,
          url: episodeUrl,
        );
        await _store.markEpisodeDownloaded(
          site: job.site,
          novelId: job.novelId,
          episodeNo: episodeNo,
          page: page,
          excludingJobId: job.id,
        );
    }
  }

  String? _lastChapterTitle(List<NarouTocEntry> entries) {
    for (final entry in entries.reversed) {
      if (entry.type == NarouTocEntryType.chapter && entry.title != null) {
        return entry.title;
      }
    }
    return null;
  }
}

class UpdateLockedException implements Exception {
  const UpdateLockedException(this.message);

  final String message;

  @override
  String toString() => message;
}
