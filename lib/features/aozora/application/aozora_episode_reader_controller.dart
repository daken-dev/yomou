import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

final aozoraEpisodeReaderProvider = FutureProvider.autoDispose
    .family<AozoraEpisodeReaderData, AozoraEpisodeReaderRequest>((
      ref,
      request,
    ) async {
      final store = ref.watch(downloadStoreProvider);
      final saved = await store.getEpisodeContent(
        site: NovelSite.aozora,
        novelId: request.novelId,
        episodeNo: 1,
      );

      if (saved != null && (saved.body?.trim().isNotEmpty ?? false)) {
        return AozoraEpisodeReaderData(
          novelId: request.novelId,
          title: saved.title ?? request.fallbackTitle ?? request.novelId,
          author: request.fallbackAuthor,
          body: saved.body!,
          images: const <String, Uint8List>{},
        );
      }

      final detail = await ref
          .watch(aozoraIndexStoreProvider)
          .findByWorkId(request.novelId);
      final zipUrl = request.textZipUrl ?? detail?.textZipUrl;
      if (zipUrl == null || zipUrl.isEmpty) {
        throw StateError('本文zip URLが見つかりません。');
      }

      final text = await ref.watch(aozoraTextClientProvider).fetchText(zipUrl);
      return AozoraEpisodeReaderData(
        novelId: request.novelId,
        title: detail?.title ?? request.fallbackTitle ?? request.novelId,
        author: detail?.author ?? request.fallbackAuthor,
        body: text.text,
        images: text.images,
      );
    });

class AozoraEpisodeReaderRequest {
  const AozoraEpisodeReaderRequest({
    required this.novelId,
    this.textZipUrl,
    this.fallbackTitle,
    this.fallbackAuthor,
  });

  final String novelId;
  final String? textZipUrl;
  final String? fallbackTitle;
  final String? fallbackAuthor;

  @override
  bool operator ==(Object other) {
    return other is AozoraEpisodeReaderRequest &&
        other.novelId == novelId &&
        other.textZipUrl == textZipUrl &&
        other.fallbackTitle == fallbackTitle &&
        other.fallbackAuthor == fallbackAuthor;
  }

  @override
  int get hashCode =>
      Object.hash(novelId, textZipUrl, fallbackTitle, fallbackAuthor);
}

class AozoraEpisodeReaderData {
  const AozoraEpisodeReaderData({
    required this.novelId,
    required this.title,
    required this.body,
    required this.images,
    this.author,
  });

  final String novelId;
  final String title;
  final String? author;
  final String body;
  final Map<String, Uint8List> images;
}
