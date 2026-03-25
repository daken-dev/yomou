import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';

final aozoraNovelDetailProvider = FutureProvider.autoDispose
    .family<AozoraNovelDetailData, String>((ref, novelId) async {
      final work = await ref
          .watch(aozoraIndexStoreProvider)
          .findByWorkId(novelId);
      if (work == null) {
        throw StateError('作品情報が見つかりませんでした。インデックスを更新してください。');
      }
      return AozoraNovelDetailData(
        novelId: work.id,
        title: work.title,
        titleReading: work.titleReading,
        subtitle: work.subtitle,
        subtitleReading: work.subtitleReading,
        originalTitle: work.originalTitle,
        firstAppearance: work.firstAppearance,
        classification: work.classification,
        writingStyle: work.writingStyle,
        workCopyright: work.workCopyright,
        publicationDate: work.publicationDate,
        csvUpdatedDate: work.csvUpdatedDate,
        author: work.author,
        role: work.role,
        birthDate: work.birthDate,
        deathDate: work.deathDate,
        personCopyright: work.personCopyright,
        cardUrl: work.cardUrl,
        textZipUrl: work.textZipUrl,
        textEncoding: work.textEncoding,
        htmlUrl: work.htmlUrl,
        htmlEncoding: work.htmlEncoding,
        inputter: work.inputter,
        proofreader: work.proofreader,
      );
    });

class AozoraNovelDetailData {
  const AozoraNovelDetailData({
    required this.novelId,
    required this.title,
    required this.author,
    required this.textZipUrl,
    this.titleReading,
    this.subtitle,
    this.subtitleReading,
    this.originalTitle,
    this.firstAppearance,
    this.classification,
    this.writingStyle,
    this.workCopyright,
    this.publicationDate,
    this.csvUpdatedDate,
    this.role,
    this.birthDate,
    this.deathDate,
    this.personCopyright,
    this.cardUrl,
    this.textEncoding,
    this.htmlUrl,
    this.htmlEncoding,
    this.inputter,
    this.proofreader,
  });

  final String novelId;
  final String title;
  final String? titleReading;
  final String? subtitle;
  final String? subtitleReading;
  final String? originalTitle;
  final String? firstAppearance;
  final String? classification;
  final String? writingStyle;
  final String? workCopyright;
  final String? publicationDate;
  final String? csvUpdatedDate;
  final String author;
  final String? role;
  final String? birthDate;
  final String? deathDate;
  final String? personCopyright;
  final String? cardUrl;
  final String textZipUrl;
  final String? textEncoding;
  final String? htmlUrl;
  final String? htmlEncoding;
  final String? inputter;
  final String? proofreader;
}
