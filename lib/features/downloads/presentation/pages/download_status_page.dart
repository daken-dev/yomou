import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/presentation/widgets/download_summary_widgets.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';

class DownloadStatusPage extends ConsumerWidget {
  const DownloadStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(downloadStatusProvider);

    return AppScaffold(
      title: 'ダウンロード状況',
      body: snapshot.when(
        loading: () => const Center(child: Text('Loading...')),
        error: (error, _) => ListView(
          children: [
            const ListTile(title: Text('状況の取得に失敗しました。')),
            ListTile(title: Text(error.toString())),
          ],
        ),
        data: (data) {
          return ListView(
            children: [
              ListTile(
                title: const Text('ジョブ集計'),
                subtitle: Text(
                  '待機 ${data.queuedJobs}\n'
                  '実行中 ${data.runningJobs}\n'
                  '失敗 ${data.failedJobs}',
                ),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(downloadSchedulerProvider).refreshAll(),
                  child: const Text('全件更新'),
                ),
              ),
              const Divider(height: 1),
              const ListTile(title: Text('保存済み作品')),
              if (data.savedNovels.isEmpty)
                const ListTile(title: Text('保存済み作品はありません。')),
              for (final novel in data.savedNovels)
                SavedNovelTile(
                  novel: novel,
                  onRefresh: () => ref
                      .read(downloadSchedulerProvider)
                      .refreshNovel(novel.site, novel.id),
                ),
              const Divider(height: 1),
              const ListTile(title: Text('最近のジョブ')),
              if (data.recentJobs.isEmpty)
                const ListTile(title: Text('ジョブはまだありません。')),
              for (final job in data.recentJobs) DownloadJobTile(job: job),
            ],
          );
        },
      ),
    );
  }
}
