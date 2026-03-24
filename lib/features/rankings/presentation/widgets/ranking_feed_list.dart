import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/novels/presentation/widgets/novel_list_item.dart';
import 'package:yomou/features/rankings/application/ranking_feed_controller.dart';

class RankingFeedList extends ConsumerWidget {
  const RankingFeedList({super.key, required this.args});

  final RankingFeedArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(rankingFeedControllerProvider(args));

    return feed.when(
      loading: () => const Center(child: Text('Loading...')),
      error: (error, stackTrace) => ListView(
        children: [
          const Text('ランキングの取得に失敗しました。'),
          Text(error.toString()),
          TextButton(
            onPressed: () =>
                ref.invalidate(rankingFeedControllerProvider(args)),
            child: const Text('再試行'),
          ),
        ],
      ),
      data: (state) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 400) {
              ref
                  .read(rankingFeedControllerProvider(args).notifier)
                  .loadNextPage();
            }
            return false;
          },
          child: ListView.builder(
            itemCount: state.items.length + _extraItemCount(state),
            itemBuilder: (context, index) {
              if (index < state.items.length) {
                return NovelListItem(novel: state.items[index]);
              }

              if (state.loadMoreErrorMessage != null) {
                return Text(state.loadMoreErrorMessage!);
              }

              if (state.hasMore && !state.isLoadingMore) {
                Future.microtask(
                  () => ref
                      .read(rankingFeedControllerProvider(args).notifier)
                      .loadNextPage(),
                );
              }

              return state.isLoadingMore
                  ? const Text('Loading...')
                  : const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  int _extraItemCount(dynamic state) {
    if (state.loadMoreErrorMessage != null ||
        state.isLoadingMore ||
        state.hasMore) {
      return 1;
    }
    return 0;
  }
}
