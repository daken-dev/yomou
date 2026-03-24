import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

class NarouNovelRecord {
  const NarouNovelRecord({required this.title, required this.ncode});

  factory NarouNovelRecord.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final ncode = json['ncode'];

    if (title is! String || ncode is! String) {
      throw const FormatException('Unexpected Narou novel record.');
    }

    return NarouNovelRecord(title: title, ncode: ncode);
  }

  final String title;
  final String ncode;

  NovelSummary toNovelSummary() {
    return NovelSummary(site: NovelSite.narou, id: ncode, title: title);
  }
}
