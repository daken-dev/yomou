import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/presentation/widgets/download_summary_widgets.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedNovels = ref.watch(savedNovelsProvider);

    return AppScaffold(
      title: '保存済み作品',
      body: savedNovels.when(
        loading: () => const Center(child: Text('Loading...')),
        error: (error, _) => ListView(
          children: [
            const ListTile(title: Text('保存済み作品の取得に失敗しました。')),
            ListTile(title: Text(error.toString())),
          ],
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: const [ListTile(title: Text('保存済み作品はありません。'))],
            );
          }

          return ListView(
            children: [
              for (final item in items)
                SavedNovelTile(
                  novel: item,
                  onRefresh: () => ref
                      .read(downloadSchedulerProvider)
                      .refreshNovel(item.site, item.id),
                ),
            ],
          );
        },
      ),
    );
  }
}
