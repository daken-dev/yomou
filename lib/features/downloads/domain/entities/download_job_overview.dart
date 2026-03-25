enum DownloadJobType { syncNovel, downloadEpisode }

extension DownloadJobTypeX on DownloadJobType {
  String get dbValue {
    return switch (this) {
      DownloadJobType.syncNovel => 'sync_novel',
      DownloadJobType.downloadEpisode => 'download_episode',
    };
  }

  String get displayName {
    return switch (this) {
      DownloadJobType.syncNovel => '作品同期',
      DownloadJobType.downloadEpisode => '各話取得',
    };
  }

  static DownloadJobType fromDb(String value) {
    return switch (value) {
      'sync_novel' => DownloadJobType.syncNovel,
      'download_episode' => DownloadJobType.downloadEpisode,
      _ => throw ArgumentError.value(value, 'value', 'Unknown job type'),
    };
  }
}

enum DownloadJobStatus { queued, running, completed, failed }

extension DownloadJobStatusX on DownloadJobStatus {
  String get dbValue {
    return switch (this) {
      DownloadJobStatus.queued => 'queued',
      DownloadJobStatus.running => 'running',
      DownloadJobStatus.completed => 'completed',
      DownloadJobStatus.failed => 'failed',
    };
  }

  String get displayName {
    return switch (this) {
      DownloadJobStatus.queued => '待機',
      DownloadJobStatus.running => '実行中',
      DownloadJobStatus.completed => '完了',
      DownloadJobStatus.failed => '失敗',
    };
  }

  static DownloadJobStatus fromDb(String value) {
    return switch (value) {
      'queued' => DownloadJobStatus.queued,
      'running' => DownloadJobStatus.running,
      'completed' => DownloadJobStatus.completed,
      'failed' => DownloadJobStatus.failed,
      _ => throw ArgumentError.value(value, 'value', 'Unknown job status'),
    };
  }
}

class DownloadJobOverview {
  const DownloadJobOverview({
    required this.id,
    required this.siteName,
    required this.novelId,
    required this.novelTitle,
    required this.type,
    required this.status,
    required this.priority,
    required this.attempts,
    required this.force,
    required this.createdAt,
    required this.updatedAt,
    this.episodeNo,
    this.lastError,
  });

  final int id;
  final String siteName;
  final String novelId;
  final String novelTitle;
  final DownloadJobType type;
  final DownloadJobStatus status;
  final int priority;
  final int attempts;
  final bool force;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? episodeNo;
  final String? lastError;
}
