import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/aozora/presentation/pages/aozora_episode_reader_page.dart';
import 'package:yomou/features/aozora/presentation/pages/aozora_novel_detail_page.dart';
import 'package:yomou/features/aozora/presentation/pages/aozora_search_page.dart';
import 'package:yomou/features/aozora/presentation/pages/aozora_search_results_page.dart';
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
import 'package:yomou/features/settings/presentation/pages/reader_settings_page.dart';
import 'package:yomou/features/settings/presentation/pages/settings_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/narou/ranking',
        builder: (context, state) {
          final periodParam = state.uri.queryParameters['period'];
          final isNewest = periodParam == 'new';
          return SiteRankingPage(
            site: NovelSite.narou,
            period: NovelRankingPeriodX.fromQueryValue(periodParam),
            isNewest: isNewest,
          );
        },
      ),
      GoRoute(
        path: '/narou-r18/ranking',
        builder: (context, state) {
          final periodParam = state.uri.queryParameters['period'];
          final isNewest = periodParam == 'new';
          return SiteRankingPage(
            site: NovelSite.narouR18,
            period: NovelRankingPeriodX.fromQueryValue(periodParam),
            isNewest: isNewest,
          );
        },
      ),
      GoRoute(
        path: '/kakuyomu/ranking',
        builder: (context, state) {
          final periodParam = state.uri.queryParameters['period'];
          final isNewest = periodParam == 'new';
          return SiteRankingPage(
            site: NovelSite.kakuyomu,
            period: NovelRankingPeriodX.fromQueryValue(periodParam),
            isNewest: isNewest,
          );
        },
      ),
      GoRoute(
        path: '/narou/novel/:id',
        builder: (context, state) => NarouNovelDetailPage(
          site: NovelSite.narou,
          novelId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/narou-r18/novel/:id',
        builder: (context, state) => NarouNovelDetailPage(
          site: NovelSite.narouR18,
          novelId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/narou/novel/:id/episode/:episodeNo',
        builder: (context, state) => NarouEpisodeReaderPage(
          site: NovelSite.narou,
          novelId: state.pathParameters['id'] ?? '',
          episodeNo: int.tryParse(state.pathParameters['episodeNo'] ?? '') ?? 1,
          episodeUrl: state.uri.queryParameters['url'],
          resumePage: int.tryParse(
            state.uri.queryParameters['resumePage'] ?? '',
          ),
          resumePageCount: int.tryParse(
            state.uri.queryParameters['resumePageCount'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/narou-r18/novel/:id/episode/:episodeNo',
        builder: (context, state) => NarouEpisodeReaderPage(
          site: NovelSite.narouR18,
          novelId: state.pathParameters['id'] ?? '',
          episodeNo: int.tryParse(state.pathParameters['episodeNo'] ?? '') ?? 1,
          episodeUrl: state.uri.queryParameters['url'],
          resumePage: int.tryParse(
            state.uri.queryParameters['resumePage'] ?? '',
          ),
          resumePageCount: int.tryParse(
            state.uri.queryParameters['resumePageCount'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/narou/search',
        builder: (context, state) =>
            const NarouSearchPage(site: NovelSite.narou),
      ),
      GoRoute(
        path: '/narou-r18/search',
        builder: (context, state) =>
            const NarouSearchPage(site: NovelSite.narouR18),
      ),
      GoRoute(
        path: '/kakuyomu/search',
        builder: (context, state) =>
            const NarouSearchPage(site: NovelSite.kakuyomu),
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
        path: '/narou-r18/search/results',
        builder: (context, state) => NarouSearchResultsPage(
          request: NovelSearchRequest(
            site: NovelSite.narouR18,
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
        path: '/kakuyomu/search/results',
        builder: (context, state) => NarouSearchResultsPage(
          request: NovelSearchRequest(
            site: NovelSite.kakuyomu,
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
        path: '/kakuyomu/novel/:id',
        builder: (context, state) => NarouNovelDetailPage(
          site: NovelSite.kakuyomu,
          novelId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/kakuyomu/novel/:id/episode/:episodeNo',
        builder: (context, state) => NarouEpisodeReaderPage(
          site: NovelSite.kakuyomu,
          novelId: state.pathParameters['id'] ?? '',
          episodeNo: int.tryParse(state.pathParameters['episodeNo'] ?? '') ?? 1,
          episodeUrl: state.uri.queryParameters['url'],
          resumePage: int.tryParse(
            state.uri.queryParameters['resumePage'] ?? '',
          ),
          resumePageCount: int.tryParse(
            state.uri.queryParameters['resumePageCount'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/aozora/search',
        builder: (context, state) => const AozoraSearchPage(),
      ),
      GoRoute(
        path: '/aozora/search/results',
        builder: (context, state) => AozoraSearchResultsPage(
          request: NovelSearchRequest(
            site: NovelSite.aozora,
            query: state.uri.queryParameters['q'] ?? '',
            target: NovelSearchTargetX.fromQueryValue(
              state.uri.queryParameters['target'],
            ),
            order: NovelSearchOrder.newest,
          ),
        ),
      ),
      GoRoute(
        path: '/aozora/novel/:id',
        builder: (context, state) =>
            AozoraNovelDetailPage(novelId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/aozora/novel/:id/read',
        builder: (context, state) => AozoraEpisodeReaderPage(
          novelId: state.pathParameters['id'] ?? '',
          textZipUrl: state.uri.queryParameters['zip'],
          title: state.uri.queryParameters['title'],
          author: state.uri.queryParameters['author'],
          resumePage: int.tryParse(
            state.uri.queryParameters['resumePage'] ?? '',
          ),
          resumePageCount: int.tryParse(
            state.uri.queryParameters['resumePageCount'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/reader',
        builder: (context, state) => const ReaderSettingsPage(),
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadStatusPage(),
      ),
    ],
  );
});
