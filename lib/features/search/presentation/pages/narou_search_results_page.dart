import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/narou/domain/entities/narou_genre.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';
import 'package:yomou/features/search/presentation/widgets/search_result_list.dart';

class NarouSearchResultsPage extends StatelessWidget {
  const NarouSearchResultsPage({super.key, required this.request});

  final NovelSearchRequest request;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '検索結果',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.hasQuery ? request.normalizedQuery : 'キーワード指定なし',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '検索範囲: ${request.target.label}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'ジャンル: ${_genreLabel(request.genreCode)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final value in NovelSearchOrderX.selectableValues)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(value.label),
                      selected: value == request.order,
                      onSelected: (_) => context.go(_locationFor(value)),
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: SearchResultList(request: request)),
        ],
      ),
    );
  }

  String _locationFor(NovelSearchOrder order) {
    final nextRequest = request.copyWith(order: order, page: 1);
    return Uri(
      path: '/narou/search/results',
      queryParameters: nextRequest.toQueryParameters(),
    ).toString();
  }

  String _genreLabel(int? code) {
    if (code == null) {
      return '指定なし';
    }
    return NarouGenre.labelOf(code);
  }
}
