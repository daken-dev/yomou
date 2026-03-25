import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/common/presentation/pages/simple_text_page.dart';
import 'package:yomou/features/downloads/presentation/pages/download_status_page.dart';
import 'package:yomou/features/home/presentation/pages/home_page.dart';
import 'package:yomou/features/narou/presentation/pages/narou_episode_reader_page.dart';
import 'package:yomou/features/narou/presentation/pages/narou_novel_detail_page.dart';
import 'package:yomou/features/novels/domain/entities/novel_ranking_period.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/rankings/presentation/pages/site_ranking_page.dart';
import 'package:yomou/features/search/presentation/pages/narou_search_page.dart';
import 'package:yomou/features/search/presentation/pages/narou_search_results_page.dart';

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
        path: '/narou/novel/:id/episode/:episodeNo',
        builder: (context, state) => NarouEpisodeReaderPage(
          novelId: state.pathParameters['id'] ?? '',
          episodeNo: int.tryParse(state.pathParameters['episodeNo'] ?? '') ?? 1,
          episodeUrl: state.uri.queryParameters['url'],
        ),
      ),
      GoRoute(
        path: '/narou/search',
        builder: (context, state) => const NarouSearchPage(),
      ),
      GoRoute(
        path: '/narou/search/results',
        builder: (context, state) => NarouSearchResultsPage(
          request: NovelSearchRequest(
            site: NovelSite.narou,
            query: state.uri.queryParameters['q'] ?? '',
            target: NovelSearchTargetX.fromQueryValue(
              state.uri.queryParameters['target'],
            ),
            genreCode: int.tryParse(state.uri.queryParameters['genre'] ?? ''),
            order: NovelSearchOrderX.fromQueryValue(
              state.uri.queryParameters['order'],
            ),
          ),
        ),
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
