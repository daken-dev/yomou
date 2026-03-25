import 'package:yomou/features/novels/domain/entities/novel_site.dart';

class NovelSummary {
  const NovelSummary({
    required this.site,
    required this.id,
    required this.title,
    this.author = '',
    this.story = '',
    this.genre = '',
    this.keyword = '',
    this.episodeCount = 0,
    this.characterCount = 0,
    this.totalPoints = 0,
    this.reviewCount = 0,
    this.bookmarkCount = 0,
    this.isComplete = false,
    this.isShortStory = false,
  });

  final NovelSite site;
  final String id;
  final String title;
  final String author;
  final String story;
  final String genre;
  final String keyword;
  final int episodeCount;
  final int characterCount;
  final int totalPoints;
  final int reviewCount;
  final int bookmarkCount;
  final bool isComplete;
  final bool isShortStory;

  List<String> get keywords =>
      keyword.isEmpty ? const [] : keyword.split(' ').where((k) => k.isNotEmpty).toList();
}
