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
    return AppScaffold(
      title: 'ランキング',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in NovelRankingPeriodX.selectableValues)
                  ChoiceChip(
                    label: Text(value.label),
                    selected: value == period,
                    onSelected: (_) =>
                        context.go('/narou/ranking?period=${value.queryValue}'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('${site.displayName} ${period.displayName}'),
          ),
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
