import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/narou/application/narou_novel_detail_controller.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';

class NarouNovelDetailPage extends ConsumerWidget {
  const NarouNovelDetailPage({super.key, required this.novelId});

  final String novelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(narouNovelDetailControllerProvider(novelId));

    return AppScaffold(
      title: '作品',
      body: detail.when(
        loading: () => const Center(child: Text('Loading...')),
        error: (error, stackTrace) => ListView(
          children: [
            const ListTile(title: Text('作品の取得に失敗しました。')),
            ListTile(title: Text(error.toString())),
            Center(
              child: TextButton(
                onPressed: () =>
                    ref.invalidate(narouNovelDetailControllerProvider(novelId)),
                child: const Text('再試行'),
              ),
            ),
          ],
        ),
        data: (state) {
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 400) {
                ref
                    .read(narouNovelDetailControllerProvider(novelId).notifier)
                    .loadNextPage();
              }
              return false;
            },
            child: ListView.builder(
              itemCount: state.items.length + _extraItemCount(state) + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.title),
                        if (state.authorName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(state.authorName),
                        ],
                      ],
                    ),
                  );
                }

                final itemIndex = index - 1;
                if (itemIndex < state.items.length) {
                  final item = state.items[itemIndex];
                  return ListTile(title: Text(item.title));
                }

                if (state.loadMoreErrorMessage case final message?) {
                  return ListTile(title: Text(message));
                }

                if (state.hasMore && !state.isLoadingMore) {
                  Future.microtask(
                    () => ref
                        .read(
                          narouNovelDetailControllerProvider(novelId).notifier,
                        )
                        .loadNextPage(),
                  );
                }

                return state.isLoadingMore
                    ? const ListTile(title: Text('Loading...'))
                    : const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  int _extraItemCount(NarouNovelDetailState state) {
    if (state.loadMoreErrorMessage != null ||
        state.isLoadingMore ||
        state.hasMore) {
      return 1;
    }
    return 0;
  }
}
