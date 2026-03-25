import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';
import 'package:yomou/features/search/presentation/widgets/search_result_list.dart';

class AozoraSearchResultsPage extends StatelessWidget {
  const AozoraSearchResultsPage({super.key, required this.request});

  final NovelSearchRequest request;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '青空文庫検索結果',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => context.push('/aozora/search'),
          tooltip: '検索条件を変更',
        ),
      ],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Text(
              request.hasQuery
                  ? '「${request.normalizedQuery}」(${request.target.label})'
                  : '全件表示 (${request.target.label})',
            ),
          ),
          Expanded(
            child: SearchResultList(
              request: request,
              showRankHighlight: false,
            ),
          ),
        ],
      ),
    );
  }
}
