import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/presentation/widgets/download_summary_widgets.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';

class DownloadStatusPage extends ConsumerWidget {
  const DownloadStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'ダウンロード状況',
      body: ListView(
        children: const [
          _JobSummarySection(),
          Divider(height: 1),
          _SavedNovelsSection(),
          Divider(height: 1),
          _RecentJobsSection(),
        ],
      ),
    );
  }
}

class _JobSummarySection extends ConsumerWidget {
  const _JobSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(downloadJobCountsProvider);
    final data = counts.value;

    if (counts.hasError) {
      return ListTile(title: Text(counts.error.toString()));
    }
    if (data == null) {
      return const ListTile(title: Text('ジョブ集計を読み込み中...'));
    }

    return ListTile(
      title: const Text('ジョブ集計'),
      subtitle: Text(
        '待機 ${data.queuedJobs}\n'
        '実行中 ${data.runningJobs}\n'
        '失敗 ${data.failedJobs}',
      ),
      trailing: TextButton(
        onPressed: () => ref.read(downloadSchedulerProvider).refreshAll(),
        child: const Text('全件更新'),
      ),
    );
  }
}

class _SavedNovelsSection extends ConsumerWidget {
  const _SavedNovelsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedNovels = ref.watch(savedNovelsProvider);
    final items = savedNovels.value;

    if (savedNovels.hasError) {
      return Column(
        children: [
          const ListTile(title: Text('保存済み作品')),
          ListTile(title: Text(savedNovels.error.toString())),
        ],
      );
    }

    return Column(
      children: [
        const ListTile(title: Text('保存済み作品')),
        if (items == null)
          const ListTile(title: Text('保存済み作品を読み込み中...'))
        else if (items.isEmpty)
          const ListTile(title: Text('保存済み作品はありません。'))
        else
          for (final novel in items)
            SavedNovelTile(
              key: ValueKey<String>('${novel.site.name}:${novel.id}'),
              novel: novel,
            ),
      ],
    );
  }
}

class _RecentJobsSection extends ConsumerWidget {
  const _RecentJobsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentJobs = ref.watch(recentDownloadJobsProvider);
    final items = recentJobs.value;

    if (recentJobs.hasError) {
      return Column(
        children: [
          const ListTile(title: Text('最近のジョブ')),
          ListTile(title: Text(recentJobs.error.toString())),
        ],
      );
    }

    return Column(
      children: [
        const ListTile(title: Text('最近のジョブ')),
        if (items == null)
          const ListTile(title: Text('ジョブを読み込み中...'))
        else if (items.isEmpty)
          const ListTile(title: Text('ジョブはまだありません。'))
        else
          for (final job in items) DownloadJobTile(job: job),
      ],
    );
  }
}
