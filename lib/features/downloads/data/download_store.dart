import 'dart:convert';

import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:yomou/core/database/app_database.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/downloads/domain/entities/download_job_overview.dart';
import 'package:yomou/features/downloads/domain/entities/download_status_snapshot.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

class DownloadStore {
  DownloadStore(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _now;

  Stream<void> get changes => _database.changes;

  Future<void> saveNovel(NovelSummary novel) async {
    final now = _isoNow();
    await _database.write((db) {
      db.execute(
        '''
        INSERT INTO saved_novels (
          site,
          novel_id,
          title,
          info_url,
          toc_url,
          created_at,
          updated_at,
          next_refresh_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(site, novel_id) DO UPDATE SET
          title = excluded.title,
          info_url = excluded.info_url,
          toc_url = excluded.toc_url,
          updated_at = excluded.updated_at
        ''',
        <Object?>[
          novel.site.name,
          novel.id,
          novel.title,
          _infoUrlFor(novel),
          _tocUrlFor(novel),
          now,
          now,
          now,
        ],
      );

      db.execute(
        '''
        INSERT OR IGNORE INTO novel_bookmarks (
          site,
          novel_id,
          episode_no,
          scroll_offset,
          page_number,
          page_count,
          updated_at
        ) VALUES (?, ?, 1, 0, 1, 0, ?)
        ''',
        <Object?>[novel.site.name, novel.id, now],
      );
    });
  }

  Future<void> removeNovel(NovelSite site, String novelId) async {
    await _database.write((db) {
      db.execute(
        '''
        DELETE FROM saved_novels
        WHERE site = ?
          AND novel_id = ?
        ''',
        <Object?>[site.name, novelId],
      );
    });
  }

  Future<bool> hasSavedNovel(NovelSite site, String novelId) async {
    return _database.read((db) {
      final rows = db.select(
        '''
        SELECT 1
        FROM saved_novels
        WHERE site = ?
          AND novel_id = ?
        LIMIT 1
        ''',
        <Object?>[site.name, novelId],
      );
      return rows.isNotEmpty;
    });
  }

  Future<Set<String>> listSavedNovelIds(NovelSite site) async {
    return _database.read((db) {
      final rows = db.select(
        'SELECT novel_id FROM saved_novels WHERE site = ?',
        <Object?>[site.name],
      );
      return rows.map((row) => row['novel_id']! as String).toSet();
    });
  }

  Future<List<SavedNovelOverview>> listSavedNovels() async {
    return _database.read((db) {
      final rows = db.select('''
        SELECT
          s.site,
          s.novel_id,
          s.title,
          s.created_at,
          s.updated_at,
          s.total_episodes,
          s.update_locked,
          s.lock_reason,
          s.last_error,
          s.last_checked_at,
          s.last_synced_at,
          s.next_refresh_at,
          COALESCE(b.episode_no, 1) AS resume_episode_no,
          (
            SELECT e.episode_url
            FROM novel_episodes e
            WHERE e.site = s.site
              AND e.novel_id = s.novel_id
              AND e.episode_no = COALESCE(b.episode_no, 1)
            LIMIT 1
          ) AS resume_episode_url,
          COALESCE(b.page_number, 1) AS resume_page_number,
          COALESCE(b.page_count, 0) AS resume_page_count,
          MAX(s.total_episodes - COALESCE(b.episode_no, 1) + 1, 0)
            AS remaining_episodes,
          (
            SELECT COUNT(*)
            FROM novel_episodes e
            WHERE e.site = s.site
              AND e.novel_id = s.novel_id
              AND e.is_downloaded = 1
          ) AS downloaded_episodes,
          (
            SELECT COUNT(*)
            FROM download_jobs j
            WHERE j.site = s.site
              AND j.novel_id = s.novel_id
              AND j.status = 'queued'
          ) AS queued_jobs,
          (
            SELECT COUNT(*)
            FROM download_jobs j
            WHERE j.site = s.site
              AND j.novel_id = s.novel_id
              AND j.status = 'running'
          ) AS running_jobs
        FROM saved_novels s
        LEFT JOIN novel_bookmarks b
          ON b.site = s.site
         AND b.novel_id = s.novel_id
        ORDER BY s.updated_at DESC, s.created_at DESC
      ''');

      return rows.map(_savedNovelOverviewFromRow).toList(growable: false);
    });
  }

  Future<SavedNovelOverview?> getSavedNovelOverview(
    NovelSite site,
    String novelId,
  ) async {
    return _database.read((db) {
      final rows = db.select(
        '''
        SELECT
          s.site,
          s.novel_id,
          s.title,
          s.created_at,
          s.updated_at,
          s.total_episodes,
          s.update_locked,
          s.lock_reason,
          s.last_error,
          s.last_checked_at,
          s.last_synced_at,
          s.next_refresh_at,
          COALESCE(b.episode_no, 1) AS resume_episode_no,
          (
            SELECT e.episode_url
            FROM novel_episodes e
            WHERE e.site = s.site
              AND e.novel_id = s.novel_id
              AND e.episode_no = COALESCE(b.episode_no, 1)
            LIMIT 1
          ) AS resume_episode_url,
          COALESCE(b.page_number, 1) AS resume_page_number,
          COALESCE(b.page_count, 0) AS resume_page_count,
          MAX(s.total_episodes - COALESCE(b.episode_no, 1) + 1, 0)
            AS remaining_episodes,
          (
            SELECT COUNT(*)
            FROM novel_episodes e
            WHERE e.site = s.site
              AND e.novel_id = s.novel_id
              AND e.is_downloaded = 1
          ) AS downloaded_episodes,
          (
            SELECT COUNT(*)
            FROM download_jobs j
            WHERE j.site = s.site
              AND j.novel_id = s.novel_id
              AND j.status = 'queued'
          ) AS queued_jobs,
          (
            SELECT COUNT(*)
            FROM download_jobs j
            WHERE j.site = s.site
              AND j.novel_id = s.novel_id
              AND j.status = 'running'
          ) AS running_jobs
        FROM saved_novels s
        LEFT JOIN novel_bookmarks b
          ON b.site = s.site
         AND b.novel_id = s.novel_id
        WHERE s.site = ?
          AND s.novel_id = ?
        LIMIT 1
        ''',
        <Object?>[site.name, novelId],
      );

      if (rows.isEmpty) {
        return null;
      }
      return _savedNovelOverviewFromRow(rows.first);
    });
  }

  Future<bool> saveReadingProgress({
    required NovelSite site,
    required String novelId,
    required int episodeNo,
    required int pageNumber,
    required int pageCount,
    int? nextEpisodeNo,
  }) async {
    return _database.write((db) {
      final savedRows = db.select(
        '''
        SELECT 1
        FROM saved_novels
        WHERE site = ?
          AND novel_id = ?
        LIMIT 1
        ''',
        <Object?>[site.name, novelId],
      );
      if (savedRows.isEmpty) {
        return false;
      }

      final normalizedEpisodeNo = episodeNo < 1 ? 1 : episodeNo;
      final normalizedPageCount = pageCount < 0 ? 0 : pageCount;
      final normalizedPageNumber = normalizedPageCount <= 0
          ? 1
          : pageNumber.clamp(1, normalizedPageCount);
      final isCompletedEpisode =
          normalizedPageCount > 0 &&
          normalizedPageNumber >= normalizedPageCount;
      final resumeEpisodeNo = isCompletedEpisode
          ? (nextEpisodeNo ?? normalizedEpisodeNo + 1)
          : normalizedEpisodeNo;
      final resumePageNumber = isCompletedEpisode ? 1 : normalizedPageNumber;
      final resumePageCount = isCompletedEpisode ? 0 : normalizedPageCount;

      final bookmarkRows = db.select(
        '''
        SELECT episode_no, page_number, page_count
        FROM novel_bookmarks
        WHERE site = ?
          AND novel_id = ?
        LIMIT 1
        ''',
        <Object?>[site.name, novelId],
      );
      if (bookmarkRows.isNotEmpty) {
        final row = bookmarkRows.first;
        final currentEpisodeNo = _intValue(row['episode_no']);
        final currentPageNumber = _intValue(row['page_number']);
        final currentPageCount = _intValue(row['page_count']);
        if (currentEpisodeNo == resumeEpisodeNo &&
            currentPageNumber == resumePageNumber &&
            currentPageCount == resumePageCount) {
          return true;
        }
      }

      final now = _isoNow();
      db.execute(
        '''
        INSERT INTO novel_bookmarks (
          site,
          novel_id,
          episode_no,
          scroll_offset,
          page_number,
          page_count,
          updated_at
        ) VALUES (?, ?, ?, 0, ?, ?, ?)
        ON CONFLICT(site, novel_id) DO UPDATE SET
          episode_no = excluded.episode_no,
          scroll_offset = 0,
          page_number = excluded.page_number,
          page_count = excluded.page_count,
          updated_at = excluded.updated_at
        ''',
        <Object?>[
          site.name,
          novelId,
          resumeEpisodeNo,
          resumePageNumber,
          resumePageCount,
          now,
        ],
      );
      return true;
    });
  }

  Future<DownloadStatusSnapshot> getStatusSnapshot({
    int recentJobLimit = 40,
  }) async {
    final savedNovels = await listSavedNovels();
    final recentJobs = await listRecentJobs(limit: recentJobLimit);
    final counts = await getJobCounts();

    return DownloadStatusSnapshot(
      queuedJobs: counts.queuedJobs,
      runningJobs: counts.runningJobs,
      failedJobs: counts.failedJobs,
      savedNovels: savedNovels,
      recentJobs: recentJobs,
    );
  }

  Future<DownloadJobCounts> getJobCounts() async {
    return _database.read((db) {
      final rows = db.select('''
        SELECT
          SUM(CASE WHEN status = 'queued' THEN 1 ELSE 0 END) AS queued_jobs,
          SUM(CASE WHEN status = 'running' THEN 1 ELSE 0 END) AS running_jobs,
          SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_jobs
        FROM download_jobs
      ''');
      final row = rows.first;
      return DownloadJobCounts(
        queuedJobs: _intValue(row['queued_jobs']),
        runningJobs: _intValue(row['running_jobs']),
        failedJobs: _intValue(row['failed_jobs']),
      );
    });
  }

  Future<List<DownloadJobOverview>> listRecentJobs({int limit = 40}) async {
    return _database.read((db) {
      final rows = db.select(
        '''
        SELECT
          j.id,
          j.site,
          j.novel_id,
          s.title AS novel_title,
          j.job_type,
          j.status,
          j.episode_no,
          j.priority,
          j.attempts,
          j.force,
          j.last_error,
          j.created_at,
          j.updated_at
        FROM download_jobs j
        INNER JOIN saved_novels s
          ON s.site = j.site
         AND s.novel_id = j.novel_id
        ORDER BY j.id DESC
        LIMIT ?
        ''',
        <Object?>[limit],
      );
      return rows.map(_downloadJobOverviewFromRow).toList(growable: false);
    });
  }

  Future<void> enqueueSyncNovel({
    required NovelSite site,
    required String novelId,
    required int priority,
    bool force = false,
  }) async {
    final now = _isoNow();
    await _database.write((db) {
      _upsertJob(
        db: db,
        site: site.name,
        novelId: novelId,
        type: DownloadJobType.syncNovel,
        priority: priority,
        now: now,
        force: force,
      );
    });
  }

  Future<void> enqueueEpisodeDownloads(
    NovelSite site,
    String novelId,
    List<EpisodeDownloadPlan> plans,
  ) async {
    if (plans.isEmpty) {
      return;
    }

    final now = _isoNow();
    await _database.write((db) {
      for (final plan in plans) {
        _upsertJob(
          db: db,
          site: site.name,
          novelId: novelId,
          type: DownloadJobType.downloadEpisode,
          priority: plan.priority,
          now: now,
          force: plan.force,
          episodeNo: plan.episodeNo,
        );
      }
    });
  }

  Future<void> enqueueRefreshForAllSaved({
    required int priority,
    bool force = true,
  }) async {
    final rows = await _database.read((db) {
      return db.select('SELECT site, novel_id FROM saved_novels');
    });

    for (final row in rows) {
      await enqueueSyncNovel(
        site: NovelSite.values.byName(row['site']! as String),
        novelId: row['novel_id']! as String,
        priority: priority,
        force: force,
      );
    }
  }

  Future<void> enqueueDueRefreshes({
    required DateTime scheduledAt,
    required int priority,
  }) async {
    final dueAt = scheduledAt.toIso8601String();
    final rows = await _database.read((db) {
      return db.select(
        '''
        SELECT site, novel_id
        FROM saved_novels
        WHERE next_refresh_at IS NULL OR next_refresh_at <= ?
        ''',
        <Object?>[dueAt],
      );
    });

    for (final row in rows) {
      await enqueueSyncNovel(
        site: NovelSite.values.byName(row['site']! as String),
        novelId: row['novel_id']! as String,
        priority: priority,
      );
    }
  }

  Future<void> requeueRunningJobs() async {
    final now = _isoNow();
    await _database.write((db) {
      db.execute(
        '''
        UPDATE download_jobs
        SET status = 'queued',
            updated_at = ?,
            started_at = NULL,
            run_after = ?
        WHERE status = 'running'
        ''',
        <Object?>[now, now],
      );
    });
  }

  Future<DownloadJobRecord?> claimNextJob() async {
    final now = _isoNow();
    return _database.write((db) {
      final rows = db.select(
        '''
        SELECT *
        FROM download_jobs
        WHERE status = 'queued'
          AND run_after <= ?
        ORDER BY priority DESC, created_at ASC, id ASC
        LIMIT 1
        ''',
        <Object?>[now],
      );

      if (rows.isEmpty) {
        return null;
      }

      final row = rows.first;
      final id = row['id']! as int;
      final attempts = _intValue(row['attempts']) + 1;
      db.execute(
        '''
        UPDATE download_jobs
        SET status = 'running',
            attempts = ?,
            updated_at = ?,
            started_at = ?
        WHERE id = ?
        ''',
        <Object?>[attempts, now, now, id],
      );

      return _downloadJobRecordFromRow(row, attempts: attempts);
    }, notify: false);
  }

  Future<void> completeJob(DownloadJobRecord job) async {
    final now = _isoNow();
    await _database.write((db) {
      db.execute(
        '''
        UPDATE download_jobs
        SET status = 'completed',
            updated_at = ?,
            completed_at = ?,
            last_error = NULL
        WHERE id = ?
        ''',
        <Object?>[now, now, job.id],
      );
    });
  }

  Future<void> failJob(
    DownloadJobRecord job,
    String error, {
    required Duration retryDelay,
    required bool retryable,
    int maxAttempts = 5,
  }) async {
    final now = _isoNow();
    await _database.write((db) {
      if (retryable && job.attempts < maxAttempts) {
        final retryAt = _now().add(retryDelay).toIso8601String();
        db.execute(
          '''
          UPDATE download_jobs
          SET status = 'queued',
              updated_at = ?,
              started_at = NULL,
              run_after = ?,
              last_error = ?
          WHERE id = ?
          ''',
          <Object?>[now, retryAt, error, job.id],
        );
        return;
      }

      db.execute(
        '''
        UPDATE download_jobs
        SET status = 'failed',
            updated_at = ?,
            completed_at = ?,
            last_error = ?
        WHERE id = ?
        ''',
        <Object?>[now, now, error, job.id],
      );
    });
  }

  Future<void> recordNovelError(
    NovelSite site,
    String novelId,
    String error,
  ) async {
    final now = _isoNow();
    await _database.write((db) {
      db.execute(
        '''
        UPDATE saved_novels
        SET last_error = ?,
            updated_at = ?
        WHERE site = ?
          AND novel_id = ?
        ''',
        <Object?>[error, now, site.name, novelId],
      );
    });
  }

  Future<SyncNovelApplyResult> applyNovelSync({
    required NovelSite site,
    required String novelId,
    required String fallbackTitle,
    required NarouInfoPage infoPage,
    required List<NarouTocPage> tocPages,
    required bool force,
    required Duration refreshInterval,
  }) async {
    final tocPayload = jsonEncode(<String, Object?>{
      'pages': tocPages.map((page) => page.toJson()).toList(growable: false),
    });
    final infoPayload = jsonEncode(infoPage.toJson());
    final episodeMetadata = _flattenEpisodes(tocPages);

    return _database.write((db) {
      final now = _isoNow();
      final savedRows = db.select(
        '''
        SELECT total_episodes
        FROM saved_novels
        WHERE site = ?
          AND novel_id = ?
        ''',
        <Object?>[site.name, novelId],
      );
      if (savedRows.isEmpty) {
        return const SyncNovelApplyResult.ready([]);
      }
      final storedEpisodeCount = savedRows.isEmpty
          ? 0
          : _intValue(savedRows.first['total_episodes']);
      final fetchedEpisodeCount = episodeMetadata.length;

      if (!force &&
          storedEpisodeCount > 0 &&
          fetchedEpisodeCount < storedEpisodeCount) {
        final reason =
            '話数が減少しました ($storedEpisodeCount -> $fetchedEpisodeCount)。'
            ' 手動更新までロックします。';
        db.execute(
          '''
          UPDATE saved_novels
          SET update_locked = 1,
              lock_reason = ?,
              last_error = ?,
              last_checked_at = ?,
              next_refresh_at = ?,
              updated_at = ?
          WHERE site = ?
            AND novel_id = ?
          ''',
          <Object?>[
            reason,
            reason,
            now,
            _now().add(refreshInterval).toIso8601String(),
            now,
            site.name,
            novelId,
          ],
        );
        return SyncNovelApplyResult.locked(reason);
      }

      db.execute(
        '''
        INSERT INTO saved_novels (
          site,
          novel_id,
          title,
          author_name,
          author_url,
          summary,
          summary_html,
          info_url,
          toc_url,
          info_payload_json,
          toc_payload_json,
          latest_episode_published,
          total_episodes,
          toc_page_count,
          update_locked,
          lock_reason,
          last_error,
          last_checked_at,
          next_refresh_at,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NULL, NULL, ?, ?, ?, ?)
        ON CONFLICT(site, novel_id) DO UPDATE SET
          title = excluded.title,
          author_name = excluded.author_name,
          author_url = excluded.author_url,
          summary = excluded.summary,
          summary_html = excluded.summary_html,
          info_url = excluded.info_url,
          toc_url = excluded.toc_url,
          info_payload_json = excluded.info_payload_json,
          toc_payload_json = excluded.toc_payload_json,
          latest_episode_published = excluded.latest_episode_published,
          total_episodes = excluded.total_episodes,
          toc_page_count = excluded.toc_page_count,
          update_locked = 0,
          lock_reason = NULL,
          last_error = NULL,
          last_checked_at = excluded.last_checked_at,
          next_refresh_at = excluded.next_refresh_at,
          updated_at = excluded.updated_at
        ''',
        <Object?>[
          site.name,
          novelId,
          _resolveNovelTitle(fallbackTitle, infoPage, tocPages),
          tocPages.firstOrNull?.authorName,
          tocPages.firstOrNull?.authorUrl ?? infoPage.authorUrl,
          tocPages.firstOrNull?.summary,
          tocPages.firstOrNull?.summaryHtml,
          infoPage.url,
          tocPages.firstOrNull?.url ?? _tocUrlForId(site, novelId),
          infoPayload,
          tocPayload,
          tocPages.firstOrNull?.latestEpisodePublished,
          fetchedEpisodeCount,
          tocPages.isEmpty ? 0 : tocPages.last.lastPage,
          now,
          _now().add(refreshInterval).toIso8601String(),
          now,
          now,
        ],
      );

      if (force) {
        _deleteMissingEpisodes(
          db,
          site: site.name,
          novelId: novelId,
          episodeNumbers: episodeMetadata
              .map((item) => item.episodeNo)
              .toList(),
        );
      }

      final bookmarkEpisode = _bookmarkEpisode(db, site.name, novelId);
      final maxBookmarkEpisode = fetchedEpisodeCount + 1;
      if (fetchedEpisodeCount > 0 && bookmarkEpisode > maxBookmarkEpisode) {
        db.execute(
          '''
          UPDATE novel_bookmarks
          SET episode_no = ?,
              updated_at = ?
          WHERE site = ?
            AND novel_id = ?
          ''',
          <Object?>[maxBookmarkEpisode, now, site.name, novelId],
        );
      }

      final downloadPlans = <EpisodeDownloadPlan>[];
      for (final metadata in episodeMetadata) {
        final existingRows = db.select(
          '''
          SELECT
            title,
            published_at,
            revised_at,
            is_downloaded
          FROM novel_episodes
          WHERE site = ?
            AND novel_id = ?
            AND episode_no = ?
          ''',
          <Object?>[site.name, novelId, metadata.episodeNo],
        );
        final existing = existingRows.isEmpty ? null : existingRows.first;
        final isDownloaded = existing == null
            ? false
            : _boolValue(existing['is_downloaded']);
        final normalizedTitle = _normalizeEpisodeMetadataText(metadata.title);
        final normalizedPublishedAt = _normalizeEpisodeMetadataText(
          metadata.publishedAt,
        );
        final normalizedRevisedAt = _normalizeEpisodeMetadataText(
          metadata.revisedAt,
        );
        final needsDownload =
            existing == null ||
            !isDownloaded ||
            _normalizeEpisodeMetadataText(existing['title'] as String?) !=
                normalizedTitle ||
            _normalizeEpisodeMetadataText(
                  existing['published_at'] as String?,
                ) !=
                normalizedPublishedAt ||
            _normalizeEpisodeMetadataText(existing['revised_at'] as String?) !=
                normalizedRevisedAt;

        if (existing == null) {
          db.execute(
            '''
            INSERT INTO novel_episodes (
              site,
              novel_id,
              episode_no,
              title,
              episode_url,
              chapter_title,
              index_page,
              published_at,
              revised_at,
              is_downloaded,
              updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            <Object?>[
              site.name,
              novelId,
              metadata.episodeNo,
              normalizedTitle ?? metadata.title,
              metadata.episodeUrl,
              metadata.chapterTitle,
              metadata.indexPage,
              normalizedPublishedAt,
              normalizedRevisedAt,
              needsDownload ? 0 : 1,
              now,
            ],
          );
        } else {
          db.execute(
            '''
            UPDATE novel_episodes
            SET title = ?,
                episode_url = ?,
                chapter_title = ?,
                index_page = ?,
                published_at = ?,
                revised_at = ?,
                is_downloaded = ?,
                updated_at = ?
            WHERE site = ?
              AND novel_id = ?
              AND episode_no = ?
            ''',
            <Object?>[
              normalizedTitle ?? metadata.title,
              metadata.episodeUrl,
              metadata.chapterTitle,
              metadata.indexPage,
              normalizedPublishedAt,
              normalizedRevisedAt,
              needsDownload ? 0 : (isDownloaded ? 1 : 0),
              now,
              site.name,
              novelId,
              metadata.episodeNo,
            ],
          );
        }

        if (needsDownload) {
          downloadPlans.add(
            EpisodeDownloadPlan(
              episodeNo: metadata.episodeNo,
              priority: _episodePriority(
                bookmarkEpisode: bookmarkEpisode,
                episodeNo: metadata.episodeNo,
              ),
              force: force,
            ),
          );
        }
      }

      return SyncNovelApplyResult.ready(downloadPlans);
    });
  }

  Future<SyncNovelApplyResult> applyAozoraNovelSync({
    required String novelId,
    required String title,
    required String authorName,
    required String? summary,
    required String? cardUrl,
    required String textZipUrl,
    required bool force,
    required Duration refreshInterval,
  }) async {
    final now = _isoNow();
    return _database.write((db) {
      final savedRows = db.select(
        '''
        SELECT 1
        FROM saved_novels
        WHERE site = ?
          AND novel_id = ?
        LIMIT 1
        ''',
        <Object?>[NovelSite.aozora.name, novelId],
      );
      if (savedRows.isEmpty) {
        return const SyncNovelApplyResult.ready([]);
      }

      db.execute(
        '''
        UPDATE saved_novels
        SET title = ?,
            author_name = ?,
            summary = ?,
            info_url = ?,
            toc_url = ?,
            total_episodes = 1,
            toc_page_count = 1,
            update_locked = 0,
            lock_reason = NULL,
            last_error = NULL,
            last_checked_at = ?,
            next_refresh_at = ?,
            updated_at = ?
        WHERE site = ?
          AND novel_id = ?
        ''',
        <Object?>[
          title,
          authorName,
          summary,
          cardUrl,
          cardUrl,
          now,
          _now().add(refreshInterval).toIso8601String(),
          now,
          NovelSite.aozora.name,
          novelId,
        ],
      );

      final existingRows = db.select(
        '''
        SELECT is_downloaded
        FROM novel_episodes
        WHERE site = ?
          AND novel_id = ?
          AND episode_no = 1
        LIMIT 1
        ''',
        <Object?>[NovelSite.aozora.name, novelId],
      );
      final existing = existingRows.isEmpty ? null : existingRows.first;
      final wasDownloaded = existing == null
          ? false
          : _boolValue(existing['is_downloaded']);
      final needsDownload = force || !wasDownloaded;

      if (existing == null) {
        db.execute(
          '''
          INSERT INTO novel_episodes (
            site,
            novel_id,
            episode_no,
            title,
            episode_url,
            index_page,
            is_downloaded,
            updated_at
          ) VALUES (?, ?, 1, ?, ?, 1, ?, ?)
          ''',
          <Object?>[
            NovelSite.aozora.name,
            novelId,
            title,
            textZipUrl,
            needsDownload ? 0 : 1,
            now,
          ],
        );
      } else {
        db.execute(
          '''
          UPDATE novel_episodes
          SET title = ?,
              episode_url = ?,
              is_downloaded = ?,
              updated_at = ?
          WHERE site = ?
            AND novel_id = ?
            AND episode_no = 1
          ''',
          <Object?>[
            title,
            textZipUrl,
            needsDownload ? 0 : 1,
            now,
            NovelSite.aozora.name,
            novelId,
          ],
        );
      }

      if (!needsDownload) {
        return const SyncNovelApplyResult.ready([]);
      }
      return const SyncNovelApplyResult.ready([
        EpisodeDownloadPlan(episodeNo: 1, priority: 3000),
      ]);
    });
  }

  Future<void> markEpisodeDownloaded({
    required NovelSite site,
    required String novelId,
    required int episodeNo,
    required NarouEpisodePage page,
    required int excludingJobId,
  }) async {
    final now = _isoNow();
    await _database.write((db) {
      db.execute(
        '''
        UPDATE novel_episodes
        SET title = COALESCE(?, title),
            preface = ?,
            preface_html = ?,
            body = ?,
            body_html = ?,
            afterword = ?,
            afterword_html = ?,
            page_payload_json = ?,
            is_downloaded = 1,
            last_downloaded_at = ?,
            updated_at = ?
        WHERE site = ?
          AND novel_id = ?
          AND episode_no = ?
        ''',
        <Object?>[
          page.title,
          page.preface,
          page.prefaceHtml,
          page.body,
          page.bodyHtml,
          page.afterword,
          page.afterwordHtml,
          jsonEncode(page.toJson()),
          now,
          now,
          site.name,
          novelId,
          episodeNo,
        ],
      );

      final counts = db.select(
        '''
        SELECT
          total_episodes,
          (
            SELECT COUNT(*)
            FROM novel_episodes e
            WHERE e.site = s.site
              AND e.novel_id = s.novel_id
              AND e.is_downloaded = 1
          ) AS downloaded_episodes,
          (
            SELECT COUNT(*)
            FROM download_jobs j
            WHERE j.site = s.site
              AND j.novel_id = s.novel_id
              AND j.id != ?
              AND j.status IN ('queued', 'running')
          ) AS active_jobs
        FROM saved_novels s
        WHERE s.site = ?
          AND s.novel_id = ?
        ''',
        <Object?>[excludingJobId, site.name, novelId],
      );
      if (counts.isEmpty) {
        return;
      }

      final row = counts.first;
      final totalEpisodes = _intValue(row['total_episodes']);
      final downloadedEpisodes = _intValue(row['downloaded_episodes']);
      final activeJobs = _intValue(row['active_jobs']);

      db.execute(
        '''
        UPDATE saved_novels
        SET last_error = NULL,
            last_synced_at = CASE
              WHEN ? > 0 AND ? >= ? AND ? = 0 THEN ?
              ELSE last_synced_at
            END
        WHERE site = ?
          AND novel_id = ?
        ''',
        <Object?>[
          totalEpisodes,
          downloadedEpisodes,
          totalEpisodes,
          activeJobs,
          now,
          site.name,
          novelId,
        ],
      );
    });
  }

  Future<void> markAozoraEpisodeDownloaded({
    required String novelId,
    required int episodeNo,
    required String? title,
    required String body,
    required int excludingJobId,
  }) async {
    final now = _isoNow();
    await _database.write((db) {
      db.execute(
        '''
        UPDATE novel_episodes
        SET title = COALESCE(?, title),
            body = ?,
            body_html = NULL,
            is_downloaded = 1,
            last_downloaded_at = ?,
            updated_at = ?
        WHERE site = ?
          AND novel_id = ?
          AND episode_no = ?
        ''',
        <Object?>[
          title,
          body,
          now,
          now,
          NovelSite.aozora.name,
          novelId,
          episodeNo,
        ],
      );

      db.execute(
        '''
        UPDATE saved_novels
        SET last_error = NULL,
            last_synced_at = ?
        WHERE site = ?
          AND novel_id = ?
        ''',
        <Object?>[now, NovelSite.aozora.name, novelId],
      );
    });
  }

  Future<EpisodeContent?> getEpisodeContent({
    required NovelSite site,
    required String novelId,
    required int episodeNo,
  }) async {
    return _database.read((db) {
      final rows = db.select(
        '''
        SELECT title, preface, body, afterword, episode_url
        FROM novel_episodes
        WHERE site = ?
          AND novel_id = ?
          AND episode_no = ?
        LIMIT 1
        ''',
        <Object?>[site.name, novelId, episodeNo],
      );
      if (rows.isEmpty) {
        return null;
      }
      final row = rows.first;
      return EpisodeContent(
        title: row['title'] as String?,
        preface: row['preface'] as String?,
        body: row['body'] as String?,
        afterword: row['afterword'] as String?,
        episodeUrl: row['episode_url'] as String?,
      );
    });
  }

  Future<String?> episodeUrlFor(
    NovelSite site,
    String novelId,
    int episodeNo,
  ) async {
    return _database.read((db) {
      final rows = db.select(
        '''
        SELECT episode_url
        FROM novel_episodes
        WHERE site = ?
          AND novel_id = ?
          AND episode_no = ?
        ''',
        <Object?>[site.name, novelId, episodeNo],
      );
      if (rows.isEmpty) {
        return null;
      }
      return rows.first['episode_url'] as String?;
    });
  }

  SavedNovelOverview _savedNovelOverviewFromRow(sqlite.Row row) {
    final totalEpisodes = _intValue(row['total_episodes']);
    final downloadedEpisodes = _intValue(row['downloaded_episodes']);
    final queuedJobs = _intValue(row['queued_jobs']);
    final runningJobs = _intValue(row['running_jobs']);
    final updateLocked = _boolValue(row['update_locked']);
    final lastError = row['last_error'] as String?;

    final state = updateLocked
        ? SavedNovelSyncState.locked
        : runningJobs > 0
        ? SavedNovelSyncState.running
        : queuedJobs > 0
        ? SavedNovelSyncState.queued
        : lastError != null
        ? SavedNovelSyncState.error
        : totalEpisodes > 0 && downloadedEpisodes >= totalEpisodes
        ? SavedNovelSyncState.synced
        : totalEpisodes > 0 && downloadedEpisodes > 0
        ? SavedNovelSyncState.partial
        : SavedNovelSyncState.queued;

    return SavedNovelOverview(
      site: NovelSite.values.byName(row['site']! as String),
      id: row['novel_id']! as String,
      title: row['title']! as String,
      state: state,
      totalEpisodes: totalEpisodes,
      downloadedEpisodes: downloadedEpisodes,
      activeQueuedJobs: queuedJobs,
      activeRunningJobs: runningJobs,
      remainingEpisodes: _intValue(row['remaining_episodes']),
      resumeEpisodeNo: _intValue(row['resume_episode_no']),
      resumeEpisodeUrl: row['resume_episode_url'] as String?,
      resumePageNumber: _intValue(row['resume_page_number']),
      resumePageCount: _intValue(row['resume_page_count']),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
      lastError: lastError,
      lockReason: row['lock_reason'] as String?,
      nextRefreshAt: _dateTimeOrNull(row['next_refresh_at']),
      lastCheckedAt: _dateTimeOrNull(row['last_checked_at']),
      lastSyncedAt: _dateTimeOrNull(row['last_synced_at']),
    );
  }

  DownloadJobOverview _downloadJobOverviewFromRow(sqlite.Row row) {
    return DownloadJobOverview(
      id: row['id']! as int,
      siteName: NovelSite.values.byName(row['site']! as String).displayName,
      novelId: row['novel_id']! as String,
      novelTitle: row['novel_title']! as String,
      type: DownloadJobTypeX.fromDb(row['job_type']! as String),
      status: DownloadJobStatusX.fromDb(row['status']! as String),
      priority: _intValue(row['priority']),
      attempts: _intValue(row['attempts']),
      force: _boolValue(row['force']),
      episodeNo: row['episode_no'] as int?,
      lastError: row['last_error'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  DownloadJobRecord _downloadJobRecordFromRow(
    sqlite.Row row, {
    required int attempts,
  }) {
    return DownloadJobRecord(
      id: row['id']! as int,
      site: NovelSite.values.byName(row['site']! as String),
      novelId: row['novel_id']! as String,
      type: DownloadJobTypeX.fromDb(row['job_type']! as String),
      priority: _intValue(row['priority']),
      attempts: attempts,
      force: _boolValue(row['force']),
      episodeNo: row['episode_no'] as int?,
    );
  }

  void _upsertJob({
    required sqlite.Database db,
    required String site,
    required String novelId,
    required DownloadJobType type,
    required int priority,
    required String now,
    required bool force,
    int? episodeNo,
  }) {
    final rows = db.select(
      '''
      SELECT id, status, priority, force
      FROM download_jobs
      WHERE site = ?
        AND novel_id = ?
        AND job_type = ?
        AND IFNULL(episode_no, -1) = IFNULL(?, -1)
        AND status IN ('queued', 'running')
      LIMIT 1
      ''',
      <Object?>[site, novelId, type.dbValue, episodeNo],
    );

    if (rows.isNotEmpty) {
      final row = rows.first;
      if (row['status'] == 'queued') {
        final nextPriority = _intValue(row['priority']);
        final nextForce = _boolValue(row['force']) || force;
        db.execute(
          '''
          UPDATE download_jobs
          SET priority = ?,
              force = ?,
              updated_at = ?
          WHERE id = ?
          ''',
          <Object?>[
            priority > nextPriority ? priority : nextPriority,
            nextForce ? 1 : 0,
            now,
            row['id'],
          ],
        );
      }
      return;
    }

    db.execute(
      '''
      INSERT INTO download_jobs (
        site,
        novel_id,
        job_type,
        episode_no,
        force,
        priority,
        status,
        attempts,
        run_after,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, 'queued', 0, ?, ?, ?)
      ''',
      <Object?>[
        site,
        novelId,
        type.dbValue,
        episodeNo,
        force ? 1 : 0,
        priority,
        now,
        now,
        now,
      ],
    );
  }

  List<EpisodeMetadata> _flattenEpisodes(List<NarouTocPage> tocPages) {
    final metadata = <EpisodeMetadata>[];
    String? currentChapter;
    for (final page in tocPages) {
      for (final entry in page.entries) {
        if (!entry.isEpisode) {
          currentChapter = entry.title;
          continue;
        }
        final episodeNo = entry.episodeNo;
        final title = entry.title;
        final url = entry.url;
        if (episodeNo == null || title == null || url == null) {
          continue;
        }
        metadata.add(
          EpisodeMetadata(
            episodeNo: episodeNo,
            title: title,
            episodeUrl: url,
            chapterTitle: currentChapter,
            indexPage: entry.indexPage,
            publishedAt: entry.publishedAt,
            revisedAt: entry.revisedAt,
          ),
        );
      }
    }
    return metadata;
  }

  int _bookmarkEpisode(sqlite.Database db, String site, String novelId) {
    final rows = db.select(
      '''
      SELECT episode_no
      FROM novel_bookmarks
      WHERE site = ?
        AND novel_id = ?
      ''',
      <Object?>[site, novelId],
    );
    if (rows.isEmpty) {
      return 1;
    }
    return _intValue(rows.first['episode_no']);
  }

  void _deleteMissingEpisodes(
    sqlite.Database db, {
    required String site,
    required String novelId,
    required List<int> episodeNumbers,
  }) {
    if (episodeNumbers.isEmpty) {
      db.execute(
        '''
        DELETE FROM novel_episodes
        WHERE site = ?
          AND novel_id = ?
        ''',
        <Object?>[site, novelId],
      );
      return;
    }

    final placeholders = List<String>.filled(
      episodeNumbers.length,
      '?',
    ).join(', ');
    db.execute(
      '''
      DELETE FROM novel_episodes
      WHERE site = ?
        AND novel_id = ?
        AND episode_no NOT IN ($placeholders)
      ''',
      <Object?>[site, novelId, ...episodeNumbers],
    );
  }

  int _episodePriority({required int bookmarkEpisode, required int episodeNo}) {
    return 3000 - (bookmarkEpisode - episodeNo).abs();
  }

  String? _normalizeEpisodeMetadataText(String? value) {
    return cleanText(value);
  }

  String _resolveNovelTitle(
    String fallbackTitle,
    NarouInfoPage infoPage,
    List<NarouTocPage> tocPages,
  ) {
    return tocPages.firstOrNull?.title ?? infoPage.title ?? fallbackTitle;
  }

  String? _infoUrlFor(NovelSummary novel) {
    return _infoUrlForId(novel.site, novel.id);
  }

  String? _tocUrlFor(NovelSummary novel) {
    return _tocUrlForId(novel.site, novel.id);
  }

  String? _infoUrlForId(NovelSite site, String novelId) {
    return switch (site) {
      NovelSite.narou =>
        'https://ncode.syosetu.com/novelview/infotop/ncode/${novelId.toLowerCase()}/',
      NovelSite.narouR18 =>
        'https://novel18.syosetu.com/novelview/infotop/ncode/${novelId.toLowerCase()}/',
      NovelSite.aozora => null,
    };
  }

  String? _tocUrlForId(NovelSite site, String novelId) {
    return switch (site) {
      NovelSite.narou => 'https://ncode.syosetu.com/${novelId.toLowerCase()}/',
      NovelSite.narouR18 =>
        'https://novel18.syosetu.com/${novelId.toLowerCase()}/',
      NovelSite.aozora => null,
    };
  }

  String _isoNow() => _now().toIso8601String();

  int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value == null) {
      return 0;
    }
    return int.parse(value.toString());
  }

  bool _boolValue(Object? value) => _intValue(value) != 0;

  DateTime? _dateTimeOrNull(Object? value) {
    final text = value as String?;
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.parse(text);
  }
}

class DownloadJobRecord {
  const DownloadJobRecord({
    required this.id,
    required this.site,
    required this.novelId,
    required this.type,
    required this.priority,
    required this.attempts,
    required this.force,
    this.episodeNo,
  });

  final int id;
  final NovelSite site;
  final String novelId;
  final DownloadJobType type;
  final int priority;
  final int attempts;
  final bool force;
  final int? episodeNo;
}

class EpisodeMetadata {
  const EpisodeMetadata({
    required this.episodeNo,
    required this.title,
    required this.episodeUrl,
    required this.chapterTitle,
    required this.indexPage,
    this.publishedAt,
    this.revisedAt,
  });

  final int episodeNo;
  final String title;
  final String episodeUrl;
  final String? chapterTitle;
  final int indexPage;
  final String? publishedAt;
  final String? revisedAt;
}

class EpisodeDownloadPlan {
  const EpisodeDownloadPlan({
    required this.episodeNo,
    required this.priority,
    this.force = false,
  });

  final int episodeNo;
  final int priority;
  final bool force;
}

class SyncNovelApplyResult {
  const SyncNovelApplyResult._({
    required this.isLocked,
    required this.downloadPlans,
    this.lockReason,
  });

  const SyncNovelApplyResult.ready(List<EpisodeDownloadPlan> downloadPlans)
    : this._(isLocked: false, downloadPlans: downloadPlans);

  const SyncNovelApplyResult.locked(String reason)
    : this._(isLocked: true, downloadPlans: const [], lockReason: reason);

  final bool isLocked;
  final List<EpisodeDownloadPlan> downloadPlans;
  final String? lockReason;
}

class DownloadJobCounts {
  const DownloadJobCounts({
    required this.queuedJobs,
    required this.runningJobs,
    required this.failedJobs,
  });

  final int queuedJobs;
  final int runningJobs;
  final int failedJobs;
}

class EpisodeContent {
  const EpisodeContent({
    required this.title,
    required this.preface,
    required this.body,
    required this.afterword,
    required this.episodeUrl,
  });

  final String? title;
  final String? preface;
  final String? body;
  final String? afterword;
  final String? episodeUrl;
}
