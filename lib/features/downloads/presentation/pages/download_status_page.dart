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
    final data = snapshot.value;

    return AppScaffold(
      title: 'ダウンロード状況',
      body: switch ((data, snapshot.hasError)) {
        (final data?, _) => ListView(
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
              SavedNovelTile(novel: novel),
            const Divider(height: 1),
            const ListTile(title: Text('最近のジョブ')),
            if (data.recentJobs.isEmpty)
              const ListTile(title: Text('ジョブはまだありません。')),
            for (final job in data.recentJobs) DownloadJobTile(job: job),
          ],
        ),
        (_, true) => ListView(
          children: [
            const ListTile(title: Text('状況の取得に失敗しました。')),
            ListTile(title: Text(snapshot.error.toString())),
          ],
        ),
        _ => const Center(child: Text('Loading...')),
      },
    );
  }
}
