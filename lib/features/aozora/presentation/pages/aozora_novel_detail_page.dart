import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/aozora/application/aozora_novel_detail_controller.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';
import 'package:yomou/features/novels/presentation/external_novel_page_launcher.dart';

enum _AozoraMenuAction { openWorkPage, saveToggle, refresh }

class AozoraNovelDetailPage extends ConsumerWidget {
  const AozoraNovelDetailPage({super.key, required this.novelId});

  final String novelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(aozoraNovelDetailProvider(novelId));
    final savedNovel = ref
        .watch(
          savedNovelOverviewProvider((
            site: NovelSite.aozora,
            novelId: novelId,
          )),
        )
        .value;

    return AppScaffold(
      title: '青空文庫作品',
      actions: [
        PopupMenuButton<_AozoraMenuAction>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'メニュー',
          itemBuilder: (context) => _menuItems(context, savedNovel),
          onSelected: (action) =>
              _onAction(context, ref, action, detail.value, savedNovel),
        ),
      ],
      floatingActionButton: detail.whenOrNull(
        data: (data) => FloatingActionButton.extended(
          onPressed: () =>
              context.push(_readLocation(data, savedNovel: savedNovel)),
          icon: const Icon(Icons.auto_stories),
          label: Text(
            savedNovel?.hasResumePageProgress == true
                ? '続きを読む ${savedNovel!.resumePageNumber}/${savedNovel.resumePageCount}'
                : '読む',
          ),
        ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          error: error,
          onRetry: () => ref.invalidate(aozoraNovelDetailProvider(novelId)),
        ),
        data: (data) => _DetailContent(
          data: data,
          onOpenWorkPage: () => unawaited(
            openWorkPageInExternalBrowser(
              context,
              NovelSite.aozora,
              novelId,
              aozoraCardUrl: data.cardUrl,
            ),
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<_AozoraMenuAction>> _menuItems(
    BuildContext context,
    SavedNovelOverview? savedNovel,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      const PopupMenuItem(
        value: _AozoraMenuAction.openWorkPage,
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
          value: _AozoraMenuAction.refresh,
          child: ListTile(
            leading: Icon(Icons.refresh_rounded),
            title: Text('更新を確認'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      if (savedNovel != null) const PopupMenuDivider(),
      PopupMenuItem(
        value: _AozoraMenuAction.saveToggle,
        child: ListTile(
          leading: Icon(
            savedNovel == null
                ? Icons.bookmark_add_outlined
                : Icons.bookmark_remove_outlined,
            color: savedNovel != null ? colorScheme.error : null,
          ),
          title: Text(
            savedNovel == null ? '保存する' : '保存を解除',
            style: savedNovel != null
                ? TextStyle(color: colorScheme.error)
                : null,
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ];
  }

  void _onAction(
    BuildContext context,
    WidgetRef ref,
    _AozoraMenuAction action,
    AozoraNovelDetailData? detail,
    SavedNovelOverview? savedNovel,
  ) {
    final scheduler = ref.read(downloadSchedulerProvider);

    switch (action) {
      case _AozoraMenuAction.openWorkPage:
        unawaited(
          openWorkPageInExternalBrowser(
            context,
            NovelSite.aozora,
            novelId,
            aozoraCardUrl: detail?.cardUrl,
          ),
        );
        break;
      case _AozoraMenuAction.refresh:
        if (savedNovel != null) {
          scheduler.refreshNovel(savedNovel.site, savedNovel.id);
        }
        break;
      case _AozoraMenuAction.saveToggle:
        if (savedNovel != null) {
          scheduler.removeNovel(savedNovel.site, savedNovel.id);
          return;
        }
        if (detail == null) {
          return;
        }
        scheduler.saveNovel(
          NovelSummary(
            site: NovelSite.aozora,
            id: detail.novelId,
            title: detail.title,
            author: detail.author,
            story: detail.subtitle ?? '',
            genre: '青空文庫',
            episodeCount: 1,
            isComplete: true,
            isShortStory: true,
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('保存しました。本文を同期します。'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        break;
    }
  }

  String _readLocation(
    AozoraNovelDetailData detail, {
    required SavedNovelOverview? savedNovel,
  }) {
    final queryParameters = <String, String>{
      'zip': detail.textZipUrl,
      'title': detail.title,
      'author': detail.author,
    };
    if (savedNovel != null && savedNovel.hasResumePageProgress) {
      queryParameters['resumePage'] = savedNovel.resumePageNumber.toString();
      queryParameters['resumePageCount'] = savedNovel.resumePageCount
          .toString();
    }

    return Uri(
      path: '/aozora/novel/${detail.novelId}/read',
      queryParameters: queryParameters,
    ).toString();
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

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.data, required this.onOpenWorkPage});

  final AozoraNovelDetailData data;
  final VoidCallback onOpenWorkPage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        _NovelHeader(data: data, onOpenWorkPage: onOpenWorkPage),
        _MetadataSection(data: data),
      ],
    );
  }
}

class _NovelHeader extends StatelessWidget {
  const _NovelHeader({required this.data, required this.onOpenWorkPage});

  final AozoraNovelDetailData data;
  final VoidCallback onOpenWorkPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              data.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            if ((data.titleReading ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  data.titleReading!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // Subtitle
            if ((data.subtitle ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data.subtitle!,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.3),
              ),
            ],

            const SizedBox(height: 12),

            // Author
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.author +
                        ((data.role ?? '').isNotEmpty ? '（${data.role}）' : ''),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoTag(
                  label: '青空文庫',
                  color: colorScheme.tertiary,
                ),
                if ((data.writingStyle ?? '').isNotEmpty)
                  _InfoTag(
                    label: data.writingStyle!,
                    color: colorScheme.secondary,
                  ),
                if ((data.workCopyright ?? '').isNotEmpty)
                  _InfoTag(
                    label: data.workCopyright!,
                    color: colorScheme.primary,
                  ),
              ],
            ),

            // Publication date
            if ((data.publicationDate ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '公開: ${data.publicationDate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // First appearance
            if ((data.firstAppearance ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_edu_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '初出: ${data.firstAppearance}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Card URL
            if (data.cardUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InkWell(
                  onTap: onOpenWorkPage,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '図書カード',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.data});

  final AozoraNovelDetailData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final rows = <({IconData icon, String label, String? value})>[
      (icon: Icons.translate_rounded, label: '原題', value: data.originalTitle),
      (
        icon: Icons.category_outlined,
        label: '分類番号',
        value: data.classification,
      ),
      (
        icon: Icons.person_outline_rounded,
        label: '生年月日',
        value: data.birthDate,
      ),
      (
        icon: Icons.person_off_outlined,
        label: '没年月日',
        value: data.deathDate,
      ),
      (
        icon: Icons.copyright_rounded,
        label: '人物著作権',
        value: data.personCopyright,
      ),
      (icon: Icons.edit_outlined, label: '入力者', value: data.inputter),
      (
        icon: Icons.spellcheck_rounded,
        label: '校正者',
        value: data.proofreader,
      ),
      (
        icon: Icons.code_rounded,
        label: 'テキスト符号化',
        value: data.textEncoding,
      ),
      (
        icon: Icons.html_rounded,
        label: 'HTML符号化',
        value: data.htmlEncoding,
      ),
      (
        icon: Icons.update_rounded,
        label: 'CSV最終更新',
        value: data.csvUpdatedDate,
      ),
    ];

    final visibleRows =
        rows.where((row) => (row.value ?? '').isNotEmpty).toList();
    if (visibleRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '作品情報',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final (index, row) in visibleRows.indexed) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        row.icon,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: Text(
                          row.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          row.value!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.color});

  final String label;
  final Color color;

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
