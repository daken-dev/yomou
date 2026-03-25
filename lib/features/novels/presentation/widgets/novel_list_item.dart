import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

class NovelListItem extends ConsumerWidget {
  const NovelListItem({super.key, required this.novel, this.onTap});

  final NovelSummary novel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(
      savedNovelIdsProvider(novel.site).select((savedIds) {
        final value = savedIds.value;
        return value?.contains(novel.id) ?? false;
      }),
    );

    return ListTile(
      onTap: onTap,
      title: Text(novel.title),
      subtitle: novel.author.isEmpty ? null : Text(novel.author),
      trailing: TextButton(
        onPressed: isSaved
            ? null
            : () => ref.read(downloadSchedulerProvider).saveNovel(novel),
        child: Text(isSaved ? '保存済み' : '保存'),
      ),
    );
  }
}
