import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/rankings/application/ranking_feed_controller.dart';
import 'package:yomou/features/rankings/presentation/widgets/ranking_feed_list.dart';
import 'package:yomou/features/search/presentation/widgets/search_result_list.dart';

/// Whether the current mode is "新着" (newest) or a ranking period.
///
/// `null` period means 新着 mode.
class SiteRankingPage extends StatelessWidget {
  const SiteRankingPage({
    super.key,
    required this.site,
    required this.period,
    this.isNewest = false,
  });

  final NovelSite site;
  final NovelRankingPeriod period;
  final bool isNewest;

  static const _narouTabs = <({String label, String? periodValue})>[
    (label: '新着', periodValue: 'new'),
    (label: '日間', periodValue: 'daily'),
    (label: '週間', periodValue: 'weekly'),
    (label: '月間', periodValue: 'monthly'),
    (label: '四半期', periodValue: 'quarterly'),
    (label: '年間', periodValue: 'yearly'),
    (label: '総合', periodValue: 'overall'),
  ];

  static const _kakuyomuTabs = <({String label, String? periodValue})>[
    (label: '新着', periodValue: 'new'),
    (label: '週間', periodValue: 'weekly'),
    (label: '総合', periodValue: 'overall'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectivePeriod = _effectivePeriod();
    final title = isNewest ? '新着一覧' : effectivePeriod.displayName;
    final routePrefix = site.routePrefix;
    final tabs = _tabsFor(site);

    return AppScaffold(
      title: title,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: '検索',
          onPressed: () => context.push('$routePrefix/search'),
        ),
      ],
      body: Column(
        children: [
          // Tab selector
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  for (final tab in tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(tab.label),
                        selected: _isSelected(
                          tab.periodValue,
                          effectivePeriod: effectivePeriod,
                        ),
                        onSelected: (_) => context.go(
                          '$routePrefix/ranking?period=${tab.periodValue}',
                        ),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              _isSelected(
                                tab.periodValue,
                                effectivePeriod: effectivePeriod,
                              )
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Feed
          Expanded(
            child: isNewest
                ? SearchResultList(
                    request: NovelSearchRequest(
                      site: site,
                      order: NovelSearchOrder.newest,
                    ),
                    showRankHighlight: false,
                  )
                : RankingFeedList(
                    args: RankingFeedArgs(site: site, period: effectivePeriod),
                  ),
          ),
        ],
      ),
    );
  }

  NovelRankingPeriod _effectivePeriod() {
    if (site != NovelSite.kakuyomu) {
      return period;
    }
    return switch (period) {
      NovelRankingPeriod.overall => NovelRankingPeriod.overall,
      NovelRankingPeriod.weekly => NovelRankingPeriod.weekly,
      _ => NovelRankingPeriod.weekly,
    };
  }

  bool _isSelected(
    String? periodValue, {
    required NovelRankingPeriod effectivePeriod,
  }) {
    if (isNewest) return periodValue == 'new';
    return periodValue == effectivePeriod.queryValue;
  }

  List<({String label, String? periodValue})> _tabsFor(NovelSite site) {
    return switch (site) {
      NovelSite.kakuyomu => _kakuyomuTabs,
      _ => _narouTabs,
    };
  }
}
