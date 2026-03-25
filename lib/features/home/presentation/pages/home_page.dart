import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
import 'package:yomou/features/downloads/presentation/widgets/download_summary_widgets.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

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
    final savedNovels = ref.watch(savedNovelsProvider);
    final items = savedNovels.value;

    return AppScaffold(
      title: '保存済み作品',
      body: switch ((items, savedNovels.hasError)) {
        (final items?, _) => Column(
          children: [
            _SortControls(
              sortKey: _sortKey,
              sortDescending: _sortDescending,
              remainingZeroToEnd: _remainingZeroToEnd,
              onSortKeyChanged: (value) {
                setState(() {
                  _sortKey = value;
                });
              },
              onSortDescendingChanged: (value) {
                setState(() {
                  _sortDescending = value;
                });
              },
              onRemainingZeroToEndChanged: (value) {
                setState(() {
                  _remainingZeroToEnd = value;
                });
              },
            ),
            Expanded(
              child: items.isEmpty
                  ? ListView(
                      children: const [ListTile(title: Text('保存済み作品はありません。'))],
                    )
                  : ListView(
                      children: [
                        for (final item in _sortItems(items))
                          SavedNovelTile(
                            novel: item,
                            onTap: () => context.push(
                              _savedNovelLocation(item.site, item.id),
                            ),
                            onRefresh: () => ref
                                .read(downloadSchedulerProvider)
                                .refreshNovel(item.site, item.id),
                          ),
                      ],
                    ),
            ),
          ],
        ),
        (_, true) => ListView(
          children: [
            const ListTile(title: Text('保存済み作品の取得に失敗しました。')),
            ListTile(title: Text(savedNovels.error.toString())),
          ],
        ),
        _ => const Center(child: Text('Loading...')),
      },
    );
  }

  List<SavedNovelOverview> _sortItems(List<SavedNovelOverview> items) {
    final sorted = items.toList(growable: false);
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
    return sorted;
  }

  String _savedNovelLocation(NovelSite site, String novelId) {
    return switch (site) {
      NovelSite.narou => '/narou/novel/$novelId',
    };
  }
}

enum HomeNovelSortKey {
  remainingEpisodes('残り話数順'),
  createdAt('追加日順'),
  updatedAt('更新日順');

  const HomeNovelSortKey(this.label);

  final String label;
}

class _SortControls extends StatelessWidget {
  const _SortControls({
    required this.sortKey,
    required this.sortDescending,
    required this.remainingZeroToEnd,
    required this.onSortKeyChanged,
    required this.onSortDescendingChanged,
    required this.onRemainingZeroToEndChanged,
  });

  final HomeNovelSortKey sortKey;
  final bool sortDescending;
  final bool remainingZeroToEnd;
  final ValueChanged<HomeNovelSortKey> onSortKeyChanged;
  final ValueChanged<bool> onSortDescendingChanged;
  final ValueChanged<bool> onRemainingZeroToEndChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          DropdownButtonFormField<HomeNovelSortKey>(
            initialValue: sortKey,
            decoration: const InputDecoration(labelText: '並べ替え'),
            items: HomeNovelSortKey.values
                .map(
                  (value) => DropdownMenuItem<HomeNovelSortKey>(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onSortKeyChanged(value);
              }
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ソート逆転'),
            value: sortDescending,
            onChanged: onSortDescendingChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('残り0を最後尾に'),
            value: remainingZeroToEnd,
            onChanged: onRemainingZeroToEndChanged,
          ),
        ],
      ),
    );
  }
}
