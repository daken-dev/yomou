import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/rankings/application/ranking_feed_controller.dart';
import 'package:yomou/features/rankings/presentation/widgets/ranking_item_card.dart';

class RankingFeedList extends ConsumerWidget {
  const RankingFeedList({super.key, required this.args});

  final RankingFeedArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(rankingFeedControllerProvider(args));
    final colorScheme = Theme.of(context).colorScheme;

    return feed.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'ランキングの取得に失敗しました',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.invalidate(rankingFeedControllerProvider(args)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('再試行'),
              ),
            ],
          ),
        ),
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
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.items.length + _extraItemCount(state),
            separatorBuilder: (context, index) {
              if (index >= state.items.length - 1) {
                return const SizedBox.shrink();
              }
              return Divider(
                height: 1,
                indent: 60,
                endIndent: 16,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              );
            },
            itemBuilder: (context, index) {
              if (index < state.items.length) {
                final novel = state.items[index];
                return RankingItemCard(
                  novel: novel,
                  rank: index + 1,
                  onTap: () => context.push('/narou/novel/${novel.id}'),
                );
              }

              if (state.loadMoreErrorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          '読み込みに失敗しました',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref
                              .read(rankingFeedControllerProvider(args).notifier)
                              .loadNextPage(),
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.hasMore && !state.isLoadingMore) {
                Future.microtask(
                  () => ref
                      .read(rankingFeedControllerProvider(args).notifier)
                      .loadNextPage(),
                );
              }

              return state.isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
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
