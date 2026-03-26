import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
import 'package:yomou/features/downloads/presentation/widgets/download_summary_widgets.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/settings/application/settings_providers.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var _sortKey = HomeNovelSortKey.remainingEpisodes;
  var _sortDescending = false;
  var _remainingZeroToEnd = true;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = switch (settingsAsync) {
      AsyncData(:final value) => value,
      _ => const AppSettings.defaults(),
    };
    final listSelection = ref.watch(
      savedNovelsProvider.select(
        (savedNovels) => _toListSelection(savedNovels),
      ),
    );

    return AppScaffold(
      title: '保存済み作品',
      actions: [
        IconButton(
          onPressed: () => setState(() => _sortDescending = !_sortDescending),
          icon: Icon(
            _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
            size: 20,
          ),
          tooltip: _sortDescending ? '降順' : '昇順',
        ),
        PopupMenuButton<Object>(
          icon: const Icon(Icons.sort),
          tooltip: '並べ替え',
          onSelected: (action) {
            setState(() {
              if (action is HomeNovelSortKey) {
                _sortKey = action;
              } else if (action == #toggleRemainingZeroToEnd) {
                _remainingZeroToEnd = !_remainingZeroToEnd;
              }
            });
          },
          itemBuilder: (context) => [
            for (final key in HomeNovelSortKey.values)
              PopupMenuItem<Object>(
                value: key,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _sortKey == key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                  ),
                  title: Text(key.label),
                ),
              ),
            const PopupMenuDivider(),
            PopupMenuItem<Object>(
              value: #toggleRemainingZeroToEnd,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _remainingZeroToEnd
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 20,
                ),
                title: const Text('読了を最後尾に'),
              ),
            ),
          ],
        ),
      ],
      body: switch (listSelection) {
        _HomeNovelListSelection(:final keys?) => keys.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.library_books_outlined, size: 48),
                    SizedBox(height: 12),
                    Text('保存済み作品はありません'),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final novelKey = keys[index];
                  return _HomeSavedNovelTile(
                    key: ValueKey<String>(
                      '${novelKey.site.name}:${novelKey.novelId}',
                    ),
                    novelKey: novelKey,
                    openDirectlyInReader:
                        settings.openHomeNovelDirectlyInReader,
                  );
                },
              ),
        _HomeNovelListSelection(:final errorText?) => ListView(
          children: [
            const ListTile(title: Text('保存済み作品の取得に失敗しました。')),
            ListTile(title: Text(errorText)),
          ],
        ),
        _ => const Center(child: Text('Loading...')),
      },
    );
  }

  _HomeNovelListSelection _toListSelection(
    AsyncValue<List<SavedNovelOverview>> savedNovels,
  ) {
    return switch (savedNovels) {
      AsyncData(:final value) => _HomeNovelListSelection.data(
        _sortKeys(value),
      ),
      AsyncError(:final error) => _HomeNovelListSelection.error(
        error.toString(),
      ),
      _ => const _HomeNovelListSelection.loading(),
    };
  }

  List<SavedNovelKey> _sortKeys(List<SavedNovelOverview> novels) {
    final sorted = novels.toList(growable: false);
    sorted.sort((left, right) {
      if (_remainingZeroToEnd) {
        final leftIsDone = left.remainingEpisodes == 0;
        final rightIsDone = right.remainingEpisodes == 0;
        if (leftIsDone != rightIsDone) {
          return leftIsDone ? 1 : -1;
        }
      }

      final result = switch (_sortKey) {
        HomeNovelSortKey.remainingEpisodes => left.remainingEpisodes.compareTo(
          right.remainingEpisodes,
        ),
        HomeNovelSortKey.createdAt => left.createdAt.compareTo(right.createdAt),
        HomeNovelSortKey.updatedAt => left.updatedAt.compareTo(right.updatedAt),
      };
      if (result != 0) {
        return _sortDescending ? -result : result;
      }
      return left.title.compareTo(right.title);
    });

    return sorted
        .map((item) => (site: item.site, novelId: item.id))
        .toList(growable: false);
  }
}

class _HomeNovelListSelection {
  const _HomeNovelListSelection.loading()
    : keys = null,
      errorText = null;

  const _HomeNovelListSelection.data(this.keys) : errorText = null;

  const _HomeNovelListSelection.error(this.errorText) : keys = null;

  final List<SavedNovelKey>? keys;
  final String? errorText;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _HomeNovelListSelection &&
        _savedNovelKeyListEquals(keys, other.keys) &&
        errorText == other.errorText;
  }

  @override
  int get hashCode {
    var hash = errorText.hashCode;
    final keys = this.keys;
    if (keys == null) {
      return hash;
    }
    for (final key in keys) {
      hash = Object.hash(hash, key.site, key.novelId);
    }
    return hash;
  }
}

bool _savedNovelKeyListEquals(
  List<SavedNovelKey>? left,
  List<SavedNovelKey>? right,
) {
  if (left == null || right == null) {
    return left == right;
  }
  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index += 1) {
    final leftItem = left[index];
    final rightItem = right[index];
    if (leftItem.site != rightItem.site ||
        leftItem.novelId != rightItem.novelId) {
      return false;
    }
  }
  return true;
}

class _HomeSavedNovelTile extends ConsumerWidget {
  const _HomeSavedNovelTile({
    super.key,
    required this.novelKey,
    required this.openDirectlyInReader,
  });

  final SavedNovelKey novelKey;
  final bool openDirectlyInReader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novel = ref.watch(savedNovelOverviewProvider(novelKey)).value;
    if (novel == null) {
      return const SizedBox.shrink();
    }

    return SavedNovelTile(
      novel: novel,
      onTap: () => context.push(
        _savedNovelLocation(novel, openDirectlyInReader: openDirectlyInReader),
      ),
    );
  }

  String _savedNovelLocation(
    SavedNovelOverview novel, {
    required bool openDirectlyInReader,
  }) {
    if (novel.site == NovelSite.aozora) {
      if (openDirectlyInReader && novel.hasResumeTarget) {
        final queryParameters = <String, String>{};
        if (novel.resumeEpisodeUrl case final episodeUrl?) {
          queryParameters['zip'] = episodeUrl;
        }
        if (novel.hasResumePageProgress) {
          queryParameters['resumePage'] = novel.resumePageNumber.toString();
          queryParameters['resumePageCount'] = novel.resumePageCount.toString();
        }

        return Uri(
          path: '/aozora/novel/${novel.id}/read',
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        ).toString();
      }
      return '/aozora/novel/${novel.id}';
    }

    if (openDirectlyInReader && novel.hasResumeTarget) {
      final queryParameters = <String, String>{};
      if (novel.resumeEpisodeUrl case final episodeUrl?) {
        queryParameters['url'] = episodeUrl;
      }
      if (novel.hasResumePageProgress) {
        queryParameters['resumePage'] = novel.resumePageNumber.toString();
        queryParameters['resumePageCount'] = novel.resumePageCount.toString();
      }

      return Uri(
        path: '/narou/novel/${novel.id}/episode/${novel.resumeEpisodeNo}',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      ).toString();
    }

    return '/narou/novel/${novel.id}';
  }
}

enum HomeNovelSortKey {
  remainingEpisodes('残り話数順'),
  createdAt('追加日順'),
  updatedAt('更新日順');

  const HomeNovelSortKey(this.label);

  final String label;
}
