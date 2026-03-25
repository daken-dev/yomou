import 'package:yomou/features/downloads/domain/entities/download_job_overview.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';

class DownloadStatusSnapshot {
  const DownloadStatusSnapshot({
    required this.queuedJobs,
    required this.runningJobs,
    required this.failedJobs,
    required this.savedNovels,
    required this.recentJobs,
  });

  final int queuedJobs;
  final int runningJobs;
  final int failedJobs;
  final List<SavedNovelOverview> savedNovels;
  final List<DownloadJobOverview> recentJobs;
}
