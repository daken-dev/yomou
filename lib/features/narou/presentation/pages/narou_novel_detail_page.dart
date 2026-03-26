import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
import 'package:yomou/features/narou/application/narou_novel_detail_controller.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/presentation/external_novel_page_launcher.dart';

enum _DetailMenuAction { openWorkPage, refresh, remove }

class NarouNovelDetailPage extends ConsumerWidget {
  const NarouNovelDetailPage({
    super.key,
    required this.site,
    required this.novelId,
  });

  final NovelSite site;
  final String novelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerArgs = (site: site, novelId: novelId);
    final detail = ref.watch(narouNovelDetailControllerProvider(providerArgs));
    final detailState = switch (detail) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final savedNovel = ref
        .watch(
          savedNovelOverviewProvider((site: site, novelId: novelId)),
        )
        .value;

    return AppScaffold(
      title: '作品詳細',
      actions: [
        PopupMenuButton<_DetailMenuAction>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'メニュー',
          onSelected: (action) =>
              _onMenuAction(context, ref, action, detailState, savedNovel),
          itemBuilder: (context) => _buildMenuItems(context, savedNovel),
        ),
      ],
      floatingActionButton: savedNovel == null || !savedNovel.hasResumeTarget
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(_resumeLocation(savedNovel)),
              label: Text(_resumeLabel(savedNovel)),
              icon: const Icon(Icons.play_arrow),
            ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          error: error,
          onRetry: () => ref.invalidate(
            narouNovelDetailControllerProvider(providerArgs),
          ),
        ),
        data: (state) =>
            _DetailContent(site: site, novelId: novelId, state: state),
      ),
    );
  }

  List<PopupMenuEntry<_DetailMenuAction>> _buildMenuItems(
    BuildContext context,
    SavedNovelOverview? savedNovel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return <PopupMenuEntry<_DetailMenuAction>>[
      const PopupMenuItem(
        value: _DetailMenuAction.openWorkPage,
        child: ListTile(
          leading: Icon(Icons.open_in_new_rounded),
          title: Text('作品ページを開く'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      if (savedNovel != null) const PopupMenuDivider(),
      if (savedNovel != null)
        const PopupMenuItem(
          value: _DetailMenuAction.refresh,
          child: ListTile(
            leading: Icon(Icons.refresh_rounded),
            title: Text('更新を確認'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      if (savedNovel != null) const PopupMenuDivider(),
      PopupMenuItem(
        value: _DetailMenuAction.remove,
        child: ListTile(
          leading: Icon(
            savedNovel == null
                ? Icons.bookmark_add_outlined
                : Icons.bookmark_remove_outlined,
            color: colorScheme.error,
          ),
          title: Text(
            savedNovel == null ? '保存する' : '保存を切り替え',
            style: TextStyle(color: colorScheme.error),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ];
  }

  void _onMenuAction(
    BuildContext context,
    WidgetRef ref,
    _DetailMenuAction action,
    NarouNovelDetailState? detailState,
    SavedNovelOverview? savedNovel,
  ) {
    final scheduler = ref.read(downloadSchedulerProvider);

    switch (action) {
      case _DetailMenuAction.openWorkPage:
        unawaited(
          openWorkPageInExternalBrowser(context, site, novelId),
        );
        break;
      case _DetailMenuAction.refresh:
        if (savedNovel == null) {
          return;
        }
        scheduler.refreshNovel(savedNovel.site, savedNovel.id);
        break;
      case _DetailMenuAction.remove:
        if (savedNovel != null) {
          scheduler.removeNovel(savedNovel.site, savedNovel.id);
          return;
        }
        if (detailState == null) {
          return;
        }
        scheduler.saveNovel(_novelSummary(detailState));
        break;
    }
  }

  NovelSummary _novelSummary(NarouNovelDetailState state) {
    return NovelSummary(
      site: site,
      id: novelId,
      title: state.title,
      author: state.authorName,
      story: state.summary,
      genre: state.infoFields['ジャンル'] ?? '',
      keyword: state.infoFields['キーワード'] ?? '',
      episodeCount: state.items.where((item) => !item.isChapter).length,
      isComplete: (state.infoFields['完結・連載'] ?? '').contains('完結'),
    );
  }

  String _resumeLocation(SavedNovelOverview novel) {
    final queryParameters = <String, String>{};
    if (novel.resumeEpisodeUrl case final episodeUrl?) {
      queryParameters['url'] = episodeUrl;
    }
    if (novel.hasResumePageProgress) {
      queryParameters['resumePage'] = novel.resumePageNumber.toString();
      queryParameters['resumePageCount'] = novel.resumePageCount.toString();
    }

    final uri = Uri(
      path: '${site.routePrefix}/novel/$novelId/episode/${novel.resumeEpisodeNo}',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return uri.toString();
  }

  String _resumeLabel(SavedNovelOverview novel) {
    final episode = '第${novel.resumeEpisodeNo}話から再開';
    if (!novel.hasResumePageProgress) {
      return episode;
    }
    return '$episode ${novel.resumePageNumber}/${novel.resumePageCount}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('作品の取得に失敗しました', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.site,
    required this.novelId,
    required this.state,
  });

  final NovelSite site;
  final String novelId;
  final NarouNovelDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400) {
          ref
              .read(
                narouNovelDetailControllerProvider(
                  (site: site, novelId: novelId),
                ).notifier,
              )
              .loadNextPage();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _NovelHeader(state: state)),
          // Episode count summary
          SliverToBoxAdapter(child: _EpisodeSummaryBar(state: state)),
          // Episode list
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 88),
            sliver: SliverList.builder(
              itemCount: state.items.length + _extraItemCount(),
              itemBuilder: (context, index) {
                if (index < state.items.length) {
                  final item = state.items[index];
                  if (item.isChapter) {
                    return _ChapterHeader(title: item.title);
                  }
                  return _EpisodeTile(
                    item: item,
                    onTap: item.episodeNo == null
                        ? null
                        : () {
                            final location = Uri(
                              path: '${site.routePrefix}/novel/$novelId/episode/${item.episodeNo}',
                              queryParameters: item.episodeUrl == null
                                  ? null
                                  : <String, String>{'url': item.episodeUrl!},
                            );
                            context.push(location.toString());
                          },
                  );
                }

                // Footer: loading / error
                if (state.loadMoreErrorMessage case final message?) {
                  return _LoadMoreError(
                    message: message,
                    onRetry: () => ref
                        .read(
                          narouNovelDetailControllerProvider(
                            (site: site, novelId: novelId),
                          ).notifier,
                        )
                        .loadNextPage(),
                  );
                }

                if (state.hasMore && !state.isLoadingMore) {
                  Future.microtask(
                    () => ref
                        .read(
                          narouNovelDetailControllerProvider(
                            (site: site, novelId: novelId),
                          ).notifier,
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
          ),
        ],
      ),
    );
  }

  int _extraItemCount() {
    if (state.loadMoreErrorMessage != null ||
        state.isLoadingMore ||
        state.hasMore) {
      return 1;
    }
    return 0;
  }
}

class _NovelHeader extends StatelessWidget {
  const _NovelHeader({required this.state});

  final NarouNovelDetailState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Extract useful fields from infoFields
    final genre = state.infoFields['ジャンル'];
    final keyword = state.infoFields['キーワード'];
    final synopsis = state.summary;
    final publishedAt = state.infoFields['掲載日'];
    final status = state.infoFields['完結・連載'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.4),
            colorScheme.surface,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              state.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // Author
            if (state.authorName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.authorName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Genre / Status chips
            if (genre != null || status != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (status != null)
                      _InfoTag(
                        label: status,
                        color: colorScheme.tertiary,
                        colorScheme: colorScheme,
                      ),
                    if (genre != null)
                      _InfoTag(
                        label: genre,
                        color: colorScheme.secondary,
                        colorScheme: colorScheme,
                      ),
                  ],
                ),
              ),
            // Published date
            if (publishedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      publishedAt,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            // Synopsis
            if (synopsis.isNotEmpty) ...[
              Text(
                synopsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            // Keywords
            if (keyword != null && keyword.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: keyword
                      .split(RegExp(r'[,\s　]+'))
                      .where((k) => k.isNotEmpty)
                      .map(
                        (k) => Text(
                          '#$k',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeSummaryBar extends StatelessWidget {
  const _EpisodeSummaryBar({required this.state});

  final NarouNovelDetailState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final episodeCount = state.items.where((item) => !item.isChapter).length;
    final chapterCount = state.items.where((item) => item.isChapter).length;

    final hasMore = state.hasMore;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            hasMore ? '$episodeCount話+' : '$episodeCount話',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (chapterCount > 0) ...[
            const SizedBox(width: 16),
            Icon(
              Icons.folder_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '$chapterCount章',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (state.lastPage > 1) ...[
            const Spacer(),
            Text(
              '${state.currentPage} / ${state.lastPage} ページ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.item, required this.onTap});

  final NarouNovelDetailListItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isEnabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (isEnabled)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.label,
    required this.color,
    required this.colorScheme,
  });

  final String label;
  final Color color;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('再試行'),
          ),
        ],
      ),
    );
  }
}
