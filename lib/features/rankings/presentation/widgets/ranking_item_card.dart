import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

class RankingItemCard extends ConsumerWidget {
  const RankingItemCard({
    super.key,
    required this.novel,
    required this.rank,
    this.onTap,
  });

  final NovelSummary novel;
  final int rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSaved = ref.watch(
      savedNovelIdsProvider(novel.site).select((savedIds) {
        final value = savedIds.value;
        return value?.contains(novel.id) ?? false;
      }),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank number
            _RankBadge(rank: rank, colorScheme: colorScheme),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    novel.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Author + genre + status
                  _MetaRow(novel: novel, colorScheme: colorScheme),
                  // Synopsis
                  if (novel.story.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      novel.story,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Stats row
                  _StatsRow(novel: novel, colorScheme: colorScheme),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Save button
            _SaveButton(
              isSaved: isSaved,
              onPressed: isSaved
                  ? null
                  : () => ref.read(downloadSchedulerProvider).saveNovel(novel),
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.colorScheme});

  final int rank;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final color = switch (rank) {
      1 => const Color(0xFFFFB300),
      2 => const Color(0xFF90A4AE),
      3 => const Color(0xFFBF8040),
      _ => colorScheme.outlineVariant,
    };

    return SizedBox(
      width: 32,
      child: Column(
        children: [
          const SizedBox(height: 2),
          if (isTop3)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            )
          else
            Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.novel, required this.colorScheme});

  final NovelSummary novel;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (novel.author.isNotEmpty)
          Text(novel.author, style: metaStyle),
        if (novel.genre.isNotEmpty) ...[
          if (novel.author.isNotEmpty)
            Text('·', style: metaStyle),
          _GenreChip(genre: novel.genre, colorScheme: colorScheme),
        ],
        if (!novel.isShortStory) ...[
          _StatusChip(
            label: novel.isComplete ? '完結' : '連載中',
            color: novel.isComplete
                ? colorScheme.tertiary
                : colorScheme.primary,
            colorScheme: colorScheme,
          ),
        ] else
          _StatusChip(
            label: '短編',
            color: colorScheme.secondary,
            colorScheme: colorScheme,
          ),
      ],
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.genre, required this.colorScheme});

  final String genre;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        genre,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.novel, required this.colorScheme});

  final NovelSummary novel;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final statStyle = TextStyle(
      fontSize: 11,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
    );

    return Row(
      children: [
        if (!novel.isShortStory && novel.episodeCount > 0) ...[
          Icon(Icons.menu_book_outlined, size: 13, color: statStyle.color),
          const SizedBox(width: 2),
          Text('${_formatNumber(novel.episodeCount)}話', style: statStyle),
          const SizedBox(width: 10),
        ],
        if (novel.characterCount > 0) ...[
          Icon(Icons.notes_outlined, size: 13, color: statStyle.color),
          const SizedBox(width: 2),
          Text('${_formatNumber(novel.characterCount)}字', style: statStyle),
          const SizedBox(width: 10),
        ],
        if (novel.totalPoints > 0) ...[
          Icon(Icons.star_outline_rounded, size: 13, color: statStyle.color),
          const SizedBox(width: 2),
          Text('${_formatNumber(novel.totalPoints)}pt', style: statStyle),
          const SizedBox(width: 10),
        ],
        if (novel.bookmarkCount > 0) ...[
          Icon(Icons.bookmark_outline_rounded, size: 13, color: statStyle.color),
          const SizedBox(width: 2),
          Text(_formatNumber(novel.bookmarkCount), style: statStyle),
        ],
      ],
    );
  }

  static String _formatNumber(int n) {
    if (n >= 100000000) {
      return '${(n / 100000000).toStringAsFixed(1)}億';
    }
    if (n >= 10000) {
      return '${(n / 10000).toStringAsFixed(1)}万';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}千';
    }
    return '$n';
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaved,
    required this.onPressed,
    required this.colorScheme,
  });

  final bool isSaved;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (isSaved) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: colorScheme.primary.withValues(alpha: 0.6),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.add_circle_outline_rounded,
          size: 22,
          color: colorScheme.primary,
        ),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: '保存',
      ),
    );
  }
}
