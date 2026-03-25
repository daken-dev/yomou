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
    final items = savedNovels.value;

    return AppScaffold(
      title: '保存済み作品',
      body: switch ((items, savedNovels.hasError)) {
        (final items?, _) =>
          items.isEmpty
              ? ListView(
                  children: const [ListTile(title: Text('保存済み作品はありません。'))],
                )
              : ListView(
                  children: [
                    for (final item in items)
                      SavedNovelTile(
                        novel: item,
                        onRefresh: () => ref
                            .read(downloadSchedulerProvider)
                            .refreshNovel(item.site, item.id),
                      ),
                  ],
                ),
        (_, true) => ListView(
          children: [
            const ListTile(title: Text('保存済み作品の取得に失敗しました。')),
            ListTile(title: Text(savedNovels.error.toString())),
          ],
        ),
        _ => const Center(child: Text('Loading...')),
      },
    );
  }
}
