import 'package:yomou/features/narou/domain/entities/narou_genre.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

class NarouNovelRecord {
  const NarouNovelRecord({
    required this.title,
    required this.ncode,
    required this.writer,
    this.story = '',
    this.genre = 0,
    this.keyword = '',
    this.generalAllNo = 0,
    this.length = 0,
    this.allPoint = 0,
    this.reviewCnt = 0,
    this.favNovelCnt = 0,
    this.end = 0,
    this.novelType = 1,
  });

  factory NarouNovelRecord.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final ncode = json['ncode'];
    final writer = json['writer'];

    if (title is! String || ncode is! String || writer is! String) {
      throw const FormatException('Unexpected Narou novel record.');
    }

    return NarouNovelRecord(
      title: title,
      ncode: ncode,
      writer: writer,
      story: (json['story'] as String?) ?? '',
      genre: (json['genre'] as num?)?.toInt() ?? 0,
      keyword: (json['keyword'] as String?) ?? '',
      generalAllNo: (json['general_all_no'] as num?)?.toInt() ?? 0,
      length: (json['length'] as num?)?.toInt() ?? 0,
      allPoint: (json['all_point'] as num?)?.toInt() ?? 0,
      reviewCnt: (json['review_cnt'] as num?)?.toInt() ?? 0,
      favNovelCnt: (json['fav_novel_cnt'] as num?)?.toInt() ?? 0,
      end: (json['end'] as num?)?.toInt() ?? 0,
      novelType: (json['noveltype'] as num?)?.toInt() ?? 1,
    );
  }

  final String title;
  final String ncode;
  final String writer;
  final String story;
  final int genre;
  final String keyword;
  final int generalAllNo;
  final int length;
  final int allPoint;
  final int reviewCnt;
  final int favNovelCnt;
  final int end;
  final int novelType;

  NovelSummary toNovelSummary() {
    return NovelSummary(
      site: NovelSite.narou,
      id: ncode,
      title: title,
      author: writer,
      story: story.replaceAll('\n', ' ').trim(),
      genre: NarouGenre.labelOf(genre),
      keyword: keyword,
      episodeCount: generalAllNo,
      characterCount: length,
      totalPoints: allPoint,
      reviewCount: reviewCnt,
      bookmarkCount: favNovelCnt,
      isComplete: end == 0,
      isShortStory: novelType == 2,
    );
  }
}
