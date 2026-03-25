import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/rankings/application/ranking_feed_controller.dart';
import 'package:yomou/features/rankings/presentation/widgets/ranking_feed_list.dart';

class SiteRankingPage extends StatelessWidget {
  const SiteRankingPage({super.key, required this.site, required this.period});

  final NovelSite site;
  final NovelRankingPeriod period;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: period.displayName,
      body: Column(
        children: [
          // Period selector
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
                  for (final value in NovelRankingPeriodX.selectableValues)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(value.label),
                        selected: value == period,
                        onSelected: (_) => context
                            .go('/narou/ranking?period=${value.queryValue}'),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: value == period
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
            child: RankingFeedList(
              args: RankingFeedArgs(site: site, period: period),
            ),
          ),
        ],
      ),
    );
  }
}
