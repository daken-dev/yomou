import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/common/presentation/pages/simple_text_page.dart';
import 'package:yomou/features/downloads/presentation/pages/download_status_page.dart';
import 'package:yomou/features/home/presentation/pages/home_page.dart';
import 'package:yomou/features/narou/presentation/pages/narou_novel_detail_page.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/rankings/presentation/pages/site_ranking_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/narou/ranking',
        builder: (context, state) => SiteRankingPage(
          site: NovelSite.narou,
          period: NovelRankingPeriodX.fromQueryValue(
            state.uri.queryParameters['period'],
          ),
        ),
      ),
      GoRoute(
        path: '/narou/novel/:id',
        builder: (context, state) =>
            NarouNovelDetailPage(novelId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/narou/search',
        builder: (context, state) =>
            const SimpleTextPage(title: '検索', body: Text('検索')),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const SimpleTextPage(title: '設定', body: Text('設定')),
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadStatusPage(),
      ),
    ],
  );
});
