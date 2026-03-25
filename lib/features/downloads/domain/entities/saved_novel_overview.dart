import 'package:yomou/features/novels/domain/entities/novel_site.dart';

enum SavedNovelSyncState { queued, running, partial, synced, error, locked }

extension SavedNovelSyncStateX on SavedNovelSyncState {
  String get displayName {
    return switch (this) {
      SavedNovelSyncState.queued => '待機',
      SavedNovelSyncState.running => '実行中',
      SavedNovelSyncState.partial => '一部完了',
      SavedNovelSyncState.synced => '同期済み',
      SavedNovelSyncState.error => '失敗',
      SavedNovelSyncState.locked => '更新ロック',
    };
  }
}

class SavedNovelOverview {
  const SavedNovelOverview({
    required this.site,
    required this.id,
    required this.title,
    required this.state,
    required this.totalEpisodes,
    required this.downloadedEpisodes,
    required this.activeQueuedJobs,
    required this.activeRunningJobs,
    required this.remainingEpisodes,
    required this.resumeEpisodeNo,
    required this.resumeEpisodeUrl,
    required this.resumePageNumber,
    required this.resumePageCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
    this.lockReason,
    this.nextRefreshAt,
    this.lastCheckedAt,
    this.lastSyncedAt,
  });

  final NovelSite site;
  final String id;
  final String title;
  final SavedNovelSyncState state;
  final int totalEpisodes;
  final int downloadedEpisodes;
  final int activeQueuedJobs;
  final int activeRunningJobs;
  final int remainingEpisodes;
  final int resumeEpisodeNo;
  final String? resumeEpisodeUrl;
  final int resumePageNumber;
  final int resumePageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastError;
  final String? lockReason;
  final DateTime? nextRefreshAt;
  final DateTime? lastCheckedAt;
  final DateTime? lastSyncedAt;

  bool get isSaved => true;

  bool get hasResumeTarget => totalEpisodes > 0 && remainingEpisodes > 0;

  bool get hasResumePageProgress => hasResumeTarget && resumePageCount > 0;
}
