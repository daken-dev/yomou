import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/rankings/presentation/widgets/ranking_item_card.dart';
import 'package:yomou/features/search/application/search_result_feed_controller.dart';

class SearchResultList extends ConsumerWidget {
  const SearchResultList({
    super.key,
    required this.request,
    this.showRankHighlight = true,
  });

  final NovelSearchRequest request;
  final bool showRankHighlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(searchResultFeedControllerProvider(request));
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return feed.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 16),
              Text('検索中...'),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 32,
                  color: colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '検索結果の取得に失敗しました',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.invalidate(searchResultFeedControllerProvider(request)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
      data: (state) {
        if (state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 32,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '該当する作品が見つかりませんでした',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.site == NovelSite.hameln
                        ? '別のキーワードや原作で検索してみてください'
                        : '別のキーワードやジャンルで検索してみてください',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 400) {
              ref
                  .read(searchResultFeedControllerProvider(request).notifier)
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
                  showRankHighlight: showRankHighlight,
                  onTap: () =>
                      context.push(_detailLocation(novel.site, novel.id)),
                );
              }

              if (state.loadMoreErrorMessage != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 20,
                          color: colorScheme.error.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '読み込みに失敗しました',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => ref
                              .read(
                                searchResultFeedControllerProvider(
                                  request,
                                ).notifier,
                              )
                              .loadNextPage(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('再試行'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.hasMore && !state.isLoadingMore) {
                Future.microtask(
                  () => ref
                      .read(
                        searchResultFeedControllerProvider(request).notifier,
                      )
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

  String _detailLocation(NovelSite site, String id) {
    return switch (site) {
      NovelSite.narou => '/narou/novel/$id',
      NovelSite.narouR18 => '/narou-r18/novel/$id',
      NovelSite.kakuyomu => '/kakuyomu/novel/$id',
      NovelSite.novelup => '/novelup/novel/$id',
      NovelSite.hameln => '/hameln/novel/$id',
      NovelSite.aozora => '/aozora/novel/$id',
    };
  }
}
