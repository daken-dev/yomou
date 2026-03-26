import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/domain/entities/download_job_overview.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/presentation/external_novel_page_launcher.dart';

enum _NovelMenuAction { openWorkPage, episodes, resume, refresh, remove }

class SavedNovelTile extends ConsumerWidget {
  const SavedNovelTile({super.key, required this.novel, this.onTap});

  final SavedNovelOverview novel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSyncing =
        novel.state == SavedNovelSyncState.running ||
        novel.state == SavedNovelSyncState.queued;
    final hasError =
        novel.state == SavedNovelSyncState.error || novel.lastError != null;
    final isComplete = novel.remainingEpisodes == 0 && novel.totalEpisodes > 0;
    final hasRemaining = novel.remainingEpisodes > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showMenu(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      novel.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSyncing)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  else if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Tooltip(
                        message: novel.lastError ?? '同期エラー',
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  PopupMenuButton<_NovelMenuAction>(
                    onSelected: (action) =>
                        unawaited(_onMenuAction(context, ref, action)),
                    icon: const Icon(Icons.more_vert, size: 20),
                    padding: EdgeInsets.zero,
                    tooltip: 'メニュー',
                    itemBuilder: (_) => _buildMenuItems(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Info row
              Row(
                children: [
                  // Remaining episodes — prominent display
                  _EpisodeCount(
                    remaining: novel.remainingEpisodes,
                    total: novel.totalEpisodes,
                    hasRemaining: hasRemaining,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.update_rounded,
                    label: _formatRelativeDate(novel.updatedAt),
                    color: colorScheme.secondary,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              // Progress bar
              if (novel.totalEpisodes > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: novel.downloadedEpisodes / novel.totalEpisodes,
                    minHeight: 3,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: isComplete
                        ? colorScheme.tertiary
                        : colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    showMenu<_NovelMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width,
        offset.dy,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      items: _buildMenuItems(context),
    ).then((action) {
      if (action == null) return;
      if (!context.mounted) return;
      unawaited(_onMenuAction(context, ref, action));
    });
  }

  List<PopupMenuEntry<_NovelMenuAction>> _buildMenuItems(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      const PopupMenuItem(
        value: _NovelMenuAction.openWorkPage,
        child: ListTile(
          leading: Icon(Icons.open_in_new_rounded),
          title: Text('作品ページを開く'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: _NovelMenuAction.episodes,
        child: ListTile(
          leading: Icon(Icons.list_rounded),
          title: Text('作品詳細'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      if (novel.hasResumeTarget)
        PopupMenuItem(
          value: _NovelMenuAction.resume,
          child: ListTile(
            leading: const Icon(Icons.auto_stories_rounded),
            title: Text('第${novel.resumeEpisodeNo}話から読む'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: _NovelMenuAction.refresh,
        child: ListTile(
          leading: Icon(Icons.refresh_rounded),
          title: Text('更新を確認'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      PopupMenuItem(
        value: _NovelMenuAction.remove,
        child: ListTile(
          leading: Icon(
            Icons.bookmark_remove_outlined,
            color: colorScheme.error,
          ),
          title: Text('保存を切り替え', style: TextStyle(color: colorScheme.error)),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ];
  }

  Future<void> _onMenuAction(
    BuildContext context,
    WidgetRef? ref,
    _NovelMenuAction action,
  ) async {
    final scheduler = ref?.read(downloadSchedulerProvider);

    switch (action) {
      case _NovelMenuAction.openWorkPage:
        final cardUrl = novel.site == NovelSite.aozora && ref != null
            ? (await ref.read(aozoraIndexStoreProvider).findByWorkId(novel.id))
                  ?.cardUrl
            : null;
        if (!context.mounted) {
          return;
        }
        await openWorkPageInExternalBrowser(
          context,
          novel.site,
          novel.id,
          aozoraCardUrl: cardUrl,
        );
        break;
      case _NovelMenuAction.episodes:
        context.push(_detailLocation());
        break;
      case _NovelMenuAction.resume:
        if (!novel.hasResumeTarget) {
          return;
        }
        context.push(_resumeLocation());
        break;
      case _NovelMenuAction.refresh:
        if (scheduler == null) {
          return;
        }
        scheduler.refreshNovel(novel.site, novel.id);
        break;
      case _NovelMenuAction.remove:
        if (scheduler == null) {
          return;
        }
        scheduler.removeNovel(novel.site, novel.id);
        break;
    }
  }

  String _detailLocation() {
    return switch (novel.site) {
      NovelSite.narou => '/narou/novel/${novel.id}',
      NovelSite.narouR18 => '/narou-r18/novel/${novel.id}',
      NovelSite.kakuyomu => '/kakuyomu/novel/${novel.id}',
      NovelSite.hameln => '/hameln/novel/${novel.id}',
      NovelSite.aozora => '/aozora/novel/${novel.id}',
    };
  }

  String _resumeLocation() {
    if (novel.site == NovelSite.aozora) {
      final queryParameters = <String, String>{};
      if (novel.resumeEpisodeUrl case final episodeUrl?) {
        queryParameters['zip'] = episodeUrl;
      }
      if (novel.hasResumePageProgress) {
        queryParameters['resumePage'] = novel.resumePageNumber.toString();
        queryParameters['resumePageCount'] = novel.resumePageCount.toString();
      }

      return Uri(
        path: '/aozora/novel/${novel.id}/read',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      ).toString();
    }

    final queryParameters = <String, String>{};
    if (novel.resumeEpisodeUrl case final episodeUrl?) {
      queryParameters['url'] = episodeUrl;
    }
    if (novel.hasResumePageProgress) {
      queryParameters['resumePage'] = novel.resumePageNumber.toString();
      queryParameters['resumePageCount'] = novel.resumePageCount.toString();
    }

    return Uri(
      path:
          '${novel.site.routePrefix}/novel/${novel.id}/episode/${novel.resumeEpisodeNo}',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }
}

class _EpisodeCount extends StatelessWidget {
  const _EpisodeCount({
    required this.remaining,
    required this.total,
    required this.hasRemaining,
    required this.colorScheme,
  });

  final int remaining;
  final int total;
  final bool hasRemaining;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.menu_book_rounded,
          size: 14,
          color: hasRemaining
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '残り$remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasRemaining
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: hasRemaining
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              TextSpan(
                text: '/$total話',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final Color color;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class DownloadJobTile extends StatelessWidget {
  const DownloadJobTile({super.key, required this.job});

  final DownloadJobOverview job;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      '${job.siteName} ${job.novelId}',
      '種別: ${job.type.displayName}',
      '状態: ${job.status.displayName}',
      if (job.episodeNo case final episodeNo?) '話: $episodeNo',
      '試行: ${job.attempts}',
      if (job.force) '強制更新',
      if (job.lastError case final lastError?) 'エラー: $lastError',
      '更新: ${_formatDateTime(job.updatedAt)}',
    ];

    return ListTile(
      dense: true,
      title: Text(job.novelTitle),
      subtitle: Text(subtitle.join('\n')),
    );
  }
}

String _formatRelativeDate(DateTime value) {
  final now = DateTime.now();
  final local = value.toLocal();
  final diff = now.difference(local);

  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}週間前';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}ヶ月前';
  return '${(diff.inDays / 365).floor()}年前';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}
