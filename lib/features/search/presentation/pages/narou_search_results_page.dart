import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/kakuyomu/domain/entities/kakuyomu_genre.dart';
import 'package:yomou/features/narou/domain/entities/narou_genre.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/search/presentation/widgets/search_result_list.dart';

class NarouSearchResultsPage extends StatelessWidget {
  const NarouSearchResultsPage({super.key, required this.request});

  final NovelSearchRequest request;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return AppScaffold(
      title: '検索結果',
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: '検索',
          onPressed: () => context.push('${request.site.routePrefix}/search'),
        ),
      ],
      body: Column(
        children: [
          // Search info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            color: colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.hasQuery
                            ? '「${request.normalizedQuery}」'
                            : 'キーワード指定なし',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Text(
                    '${_targetOrOriginalLabel()} · ${_genreLabel(request.genreCode, request.original)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Order selector
          Container(
            width: double.infinity,
            color: colorScheme.surfaceContainerLow,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  for (final value in _searchOrdersFor(request.site))
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(value.label),
                        selected: value == request.order,
                        onSelected: (_) => context.go(_locationFor(value)),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: value == request.order
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: value == request.order
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        selectedColor: colorScheme.primaryContainer,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: SearchResultList(
              request: request,
              showRankHighlight: request.order != NovelSearchOrder.newest,
            ),
          ),
        ],
      ),
    );
  }

  String _locationFor(NovelSearchOrder order) {
    final nextRequest = request.copyWith(order: order, page: 1);
    return Uri(
      path: '${request.site.routePrefix}/search/results',
      queryParameters: nextRequest.toQueryParameters(),
    ).toString();
  }

  String _targetOrOriginalLabel() {
    return request.site == NovelSite.hameln ? '原作検索' : request.target.label;
  }

  String _genreLabel(int? code, String? original) {
    if (request.site == NovelSite.hameln) {
      if (original == null || original.isEmpty) {
        return '全原作';
      }
      return original.replaceFirst('原作：', '');
    }
    if (code == null) {
      return '全ジャンル';
    }
    if (request.site == NovelSite.kakuyomu) {
      return KakuyomuGenre.labelOfCode(code);
    }
    return NarouGenre.labelOf(code);
  }
}

List<NovelSearchOrder> _searchOrdersFor(NovelSite site) {
  return switch (site) {
    NovelSite.kakuyomu => const <NovelSearchOrder>[
      NovelSearchOrder.newest,
      NovelSearchOrder.weeklyPoint,
      NovelSearchOrder.overallPoint,
    ],
    NovelSite.hameln => NovelSearchOrderX.selectableValues,
    _ => NovelSearchOrderX.selectableValues,
  };
}
