import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';

final narouEpisodeReaderProvider = FutureProvider.autoDispose
    .family<NarouEpisodeReaderData, NarouEpisodeReaderRequest>((
      ref,
      request,
    ) async {
      final page = await ref
          .watch(narouWebClientProvider)
          .fetchEpisodePage(
            request.novelId,
            request.episodeNo,
            url: request.episodeUrl,
          );

      return NarouEpisodeReaderData(
        page: page,
        previousEpisodeNo:
            extractEpisodeNumber(page.prevUrl) ?? _previousEpisodeNo(page),
        nextEpisodeNo:
            extractEpisodeNumber(page.nextUrl) ?? _nextEpisodeNo(page),
      );
    });

class NarouEpisodeReaderRequest {
  const NarouEpisodeReaderRequest({
    required this.novelId,
    required this.episodeNo,
    this.episodeUrl,
  });

  final String novelId;
  final int episodeNo;
  final String? episodeUrl;

  @override
  bool operator ==(Object other) {
    return other is NarouEpisodeReaderRequest &&
        other.novelId == novelId &&
        other.episodeNo == episodeNo &&
        other.episodeUrl == episodeUrl;
  }

  @override
  int get hashCode => Object.hash(novelId, episodeNo, episodeUrl);
}

class NarouEpisodeReaderData {
  const NarouEpisodeReaderData({
    required this.page,
    required this.previousEpisodeNo,
    required this.nextEpisodeNo,
  });

  final NarouEpisodePage page;
  final int? previousEpisodeNo;
  final int? nextEpisodeNo;
}

int? _previousEpisodeNo(NarouEpisodePage page) {
  final current = page.sequenceCurrent;
  if (current == null || current <= 1) {
    return null;
  }
  return current - 1;
}

int? _nextEpisodeNo(NarouEpisodePage page) {
  final current = page.sequenceCurrent;
  final total = page.sequenceTotal;
  if (current == null || total == null || current >= total) {
    return null;
  }
  return current + 1;
}
