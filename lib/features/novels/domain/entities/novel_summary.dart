import 'package:yomou/features/novels/domain/entities/novel_site.dart';

class NovelSummary {
  const NovelSummary({
    required this.site,
    required this.id,
    required this.title,
    this.author = '',
  });

  final NovelSite site;
  final String id;
  final String title;
  final String author;
}
