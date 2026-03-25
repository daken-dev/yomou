import 'package:flutter/material.dart';
import 'package:yomou/features/downloads/domain/entities/download_job_overview.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';

class SavedNovelTile extends StatelessWidget {
  const SavedNovelTile({
    super.key,
    required this.novel,
    required this.onRefresh,
  });

  final SavedNovelOverview novel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      '状態: ${novel.state.displayName}',
      '各話: ${novel.downloadedEpisodes}/${novel.totalEpisodes}',
      if (novel.activeRunningJobs > 0 || novel.activeQueuedJobs > 0)
        'ジョブ: 実行中 ${novel.activeRunningJobs} / 待機 ${novel.activeQueuedJobs}',
      if (novel.lockReason case final lockReason?) 'ロック: $lockReason',
      if (novel.lastError case final lastError?) 'エラー: $lastError',
      if (novel.lastCheckedAt case final lastCheckedAt?)
        '確認: ${_formatDateTime(lastCheckedAt)}',
      if (novel.lastSyncedAt case final lastSyncedAt?)
        '完了: ${_formatDateTime(lastSyncedAt)}',
    ];

    return ListTile(
      title: Text(novel.title),
      subtitle: Text(subtitle.join('\n')),
      trailing: TextButton(onPressed: onRefresh, child: const Text('更新')),
    );
  }
}

class DownloadJobTile extends StatelessWidget {
  const DownloadJobTile({super.key, required this.job});

  final DownloadJobOverview job;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      '${job.siteName} ${job.novelId}',
      '種別: ${job.type.displayName}',
      '状態: ${job.status.displayName}',
      if (job.episodeNo case final episodeNo?) '話: $episodeNo',
      '試行: ${job.attempts}',
      if (job.force) '強制更新',
      if (job.lastError case final lastError?) 'エラー: $lastError',
      '更新: ${_formatDateTime(job.updatedAt)}',
    ];

    return ListTile(
      dense: true,
      title: Text(job.novelTitle),
      subtitle: Text(subtitle.join('\n')),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}
