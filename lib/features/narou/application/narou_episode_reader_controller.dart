import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/hameln/data/hameln_web_client.dart';
import 'package:yomou/features/kakuyomu/data/kakuyomu_web_client.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novelup/data/novelup_web_client.dart';

final narouEpisodeReaderProvider = FutureProvider.autoDispose
    .family<NarouEpisodeReaderData, NarouEpisodeReaderRequest>(
      (ref, request) => fetchNarouEpisodeReaderData(ref, request),
    );

Future<NarouEpisodeReaderData> fetchNarouEpisodeReaderData(
  Ref ref,
  NarouEpisodeReaderRequest request,
) async {
  final page = switch (request.site) {
    NovelSite.kakuyomu =>
      await ref
          .read(kakuyomuWebClientProvider)
          .fetchEpisodePage(
            request.novelId,
            request.episodeNo,
            url: request.episodeUrl,
          ),
    NovelSite.novelup =>
      await ref
          .read(novelupWebClientProvider)
          .fetchEpisodePage(
            request.novelId,
            request.episodeNo,
            url: request.episodeUrl,
          ),
    NovelSite.hameln =>
      await ref
          .read(hamelnWebClientProvider)
          .fetchEpisodePage(
            request.novelId,
            request.episodeNo,
            url: request.episodeUrl,
          ),
    _ =>
      await ref
          .read(narouWebClientProvider)
          .fetchEpisodePage(
            request.novelId,
            request.episodeNo,
            site: request.site,
            url: request.episodeUrl,
          ),
  };

  return NarouEpisodeReaderData(
    page: page,
    previousEpisodeNo: request.site == NovelSite.novelup
        ? _previousEpisodeNo(page)
        : extractEpisodeNumber(page.prevUrl) ?? _previousEpisodeNo(page),
    nextEpisodeNo: request.site == NovelSite.novelup
        ? _nextEpisodeNo(page)
        : extractEpisodeNumber(page.nextUrl) ?? _nextEpisodeNo(page),
  );
}

Future<NarouEpisodeReaderData> fetchNarouEpisodeReaderDataWithWidgetRef(
  WidgetRef ref,
  NarouEpisodeReaderRequest request,
) async {
  final page = switch (request.site) {
    NovelSite.kakuyomu =>
      await ref
          .read(kakuyomuWebClientProvider)
          .fetchEpisodePage(
            request.novelId,
            request.episodeNo,
            url: request.episodeUrl,
          ),
    NovelSite.novelup =>
      await ref
          .read(novelupWebClientProvider)
          .fetchEpisodePage(
            request.novelId,
            request.episodeNo,
            url: request.episodeUrl,
          ),
    NovelSite.hameln =>
      await ref
          .read(hamelnWebClientProvider)
          .fetchEpisodePage(
            request.novelId,
            request.episodeNo,
            url: request.episodeUrl,
          ),
    _ =>
      await ref
          .read(narouWebClientProvider)
          .fetchEpisodePage(
            request.novelId,
            request.episodeNo,
            site: request.site,
            url: request.episodeUrl,
          ),
  };

  return NarouEpisodeReaderData(
    page: page,
    previousEpisodeNo: request.site == NovelSite.novelup
        ? _previousEpisodeNo(page)
        : extractEpisodeNumber(page.prevUrl) ?? _previousEpisodeNo(page),
    nextEpisodeNo: request.site == NovelSite.novelup
        ? _nextEpisodeNo(page)
        : extractEpisodeNumber(page.nextUrl) ?? _nextEpisodeNo(page),
  );
}

class NarouEpisodeReaderRequest {
  const NarouEpisodeReaderRequest({
    required this.site,
    required this.novelId,
    required this.episodeNo,
    this.episodeUrl,
  });

  final NovelSite site;
  final String novelId;
  final int episodeNo;
  final String? episodeUrl;

  @override
  bool operator ==(Object other) {
    return other is NarouEpisodeReaderRequest &&
        other.site == site &&
        other.novelId == novelId &&
        other.episodeNo == episodeNo &&
        other.episodeUrl == episodeUrl;
  }

  @override
  int get hashCode => Object.hash(site, novelId, episodeNo, episodeUrl);
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
