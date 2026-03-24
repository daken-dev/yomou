import 'package:flutter/widgets.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

class NovelListItem extends StatelessWidget {
  const NovelListItem({super.key, required this.novel});

  final NovelSummary novel;

  @override
  Widget build(BuildContext context) {
    return Text(novel.title);
  }
}
