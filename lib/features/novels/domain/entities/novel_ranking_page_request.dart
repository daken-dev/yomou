import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

class NovelRankingPageRequest {
  const NovelRankingPageRequest({
    required this.site,
    required this.period,
    required this.page,
    required this.pageSize,
  });

  final NovelSite site;
  final NovelRankingPeriod period;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NovelRankingPageRequest &&
            site == other.site &&
            period == other.period &&
            page == other.page &&
            pageSize == other.pageSize;
  }

  @override
  int get hashCode => Object.hash(site, period, page, pageSize);
}
