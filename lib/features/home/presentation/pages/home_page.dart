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
                  : Builder(
                      builder: (context) {
                        final sorted = _sortItems(items);
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 16),
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final item = sorted[index];
                            return SavedNovelTile(
                              novel: item,
                              onTap: () => context.push(
                                _savedNovelLocation(item.site, item.id),
                              ),
                            );
                          },
                        );
                      },
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          // Sort key selector as segmented button
          Expanded(
            child: SegmentedButton<HomeNovelSortKey>(
              segments: HomeNovelSortKey.values
                  .map(
                    (value) => ButtonSegment<HomeNovelSortKey>(
                      value: value,
                      label: Text(value.label, style: const TextStyle(fontSize: 11)),
                    ),
                  )
                  .toList(growable: false),
              selected: {sortKey},
              onSelectionChanged: (value) => onSortKeyChanged(value.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Sort direction toggle
          IconButton(
            onPressed: () => onSortDescendingChanged(!sortDescending),
            icon: Icon(
              sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 20,
            ),
            tooltip: sortDescending ? '降順' : '昇順',
            visualDensity: VisualDensity.compact,
          ),
          // Zero remaining to end toggle
          IconButton(
            onPressed: () => onRemainingZeroToEndChanged(!remainingZeroToEnd),
            icon: Icon(
              remainingZeroToEnd
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              size: 20,
              color: remainingZeroToEnd ? colorScheme.primary : null,
            ),
            tooltip: '読了を最後尾に',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
