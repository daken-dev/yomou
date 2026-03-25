import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kumihan/kumihan.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/narou/application/narou_episode_reader_controller.dart';
import 'package:yomou/features/narou/data/narou_kumihan_parser.dart';
import 'package:yomou/features/narou/data/narou_episode_image_cache.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/settings/application/settings_providers.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class NarouEpisodeReaderPage extends ConsumerStatefulWidget {
  const NarouEpisodeReaderPage({
    super.key,
    required this.novelId,
    required this.episodeNo,
    this.episodeUrl,
    this.resumePage,
    this.resumePageCount,
  });

  final String novelId;
  final int episodeNo;
  final String? episodeUrl;
  final int? resumePage;
  final int? resumePageCount;

  @override
  ConsumerState<NarouEpisodeReaderPage> createState() =>
      _NarouEpisodeReaderPageState();
}

class _NarouEpisodeReaderPageState
    extends ConsumerState<NarouEpisodeReaderPage> {
  final KumihanController _kumihanController = KumihanController();

  late int _currentEpisodeNo;
  late String? _currentEpisodeUrl;
  var _controlsVisible = false;
  var _nextStartPosition = _EpisodeStartPosition.firstPage;
  NarouEpisodeReaderData? _latestData;
  _PendingRestorePosition? _pendingRestorePosition;
  Timer? _saveProgressDebounce;
  String? _documentConfigKey;
  KumihanDocument? _cachedDocument;

  @override
  void initState() {
    super.initState();
    _currentEpisodeNo = widget.episodeNo;
    _currentEpisodeUrl = widget.episodeUrl;
    if (widget.resumePage != null &&
        widget.resumePageCount != null &&
        widget.resumePage! > 0 &&
        widget.resumePageCount! > 0) {
      _pendingRestorePosition = _PendingRestorePosition(
        pageNumber: widget.resumePage!,
        pageCount: widget.resumePageCount!,
      );
    }
    _applyFullscreenMode();
  }

  @override
  void dispose() {
    _saveProgressDebounce?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = NarouEpisodeReaderRequest(
      novelId: widget.novelId,
      episodeNo: _currentEpisodeNo,
      episodeUrl: _currentEpisodeUrl,
    );
    final episodeAsync = ref.watch(narouEpisodeReaderProvider(request));
    final appSettingsAsync = ref.watch(appSettingsProvider);
    final appSettings = switch (appSettingsAsync) {
      AsyncData(:final value) => value,
      _ => const AppSettings.defaults(),
    };
    final readerSettings = appSettings.reader;
    final imageLoader = ref.watch(narouEpisodeImageCacheProvider).loadImage;
    final snapshot = _kumihanController.snapshot;
    final readerTheme = readerSettings.toKumihanTheme(
      paperTexture: const AssetImage('assets/paper_textures/03.jpg'),
    );

    return Scaffold(
      backgroundColor: readerTheme.paperColor,
      body: switch (episodeAsync) {
        AsyncData(:final value) => _buildReader(
          context,
          data: value,
          imageLoader: imageLoader,
          snapshot: snapshot,
          readerSettings: readerSettings,
          readerTheme: readerTheme,
        ),
        AsyncError(:final error) => _buildError(context, error, request),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildReader(
    BuildContext context, {
    required NarouEpisodeReaderData data,
    required Future<ui.Image?> Function(String) imageLoader,
    required KumihanSnapshot snapshot,
    required ReaderSettings readerSettings,
    required KumihanThemeData readerTheme,
  }) {
    _latestData = data;
    final document = _documentFor(data: data, readerSettings: readerSettings);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final desiredSpreadMode =
        readerSettings.enableLandscapeDoublePage && isLandscape
        ? KumihanSpreadMode.doublePage
        : KumihanSpreadMode.single;
    _syncReaderModes(
      desiredWritingMode: readerSettings.writingMode.kumihanValue,
      desiredSpreadMode: desiredSpreadMode,
      snapshot: snapshot,
    );

    final pageTitle = data.page.title ?? '本文';
    final novelTitle = data.page.novelTitle ?? widget.novelId;
    final pageLabel = snapshot.totalPages > 0
        ? '${snapshot.currentPage + 1} / ${snapshot.totalPages}'
        : '0 / 0';
    final episodeLabel =
        data.page.sequenceCurrent != null && data.page.sequenceTotal != null
        ? '${data.page.sequenceCurrent} / ${data.page.sequenceTotal}'
        : null;

    return Stack(
      children: [
        Positioned.fill(
          child: KumihanCanvas(
            key: ValueKey<String>(
              '${widget.novelId}:$_currentEpisodeNo:${_currentEpisodeUrl ?? ''}',
            ),
            controller: _kumihanController,
            document: document,
            imageLoader: imageLoader,
            initialSpread: desiredSpreadMode,
            initialWritingMode: readerSettings.writingMode.kumihanValue,
            layout: readerSettings.layout,
            theme: readerTheme,
            tapHandler: _handleTap,
            onSnapshotChanged: (snapshot) =>
                _handleSnapshotChanged(data: data, snapshot: snapshot),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _controlsVisible ? 1 : 0,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.14),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControls,
                  child: SafeArea(
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.pop(),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        novelTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        pageTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  pageLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      context.push('/settings/reader'),
                                  icon: const Icon(
                                    Icons.settings,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'リーダー設定',
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: data.previousEpisodeNo == null
                                        ? null
                                        : () => _openEpisode(
                                            episodeNo: data.previousEpisodeNo!,
                                            episodeUrl: data.page.prevUrl,
                                            startPosition:
                                                _EpisodeStartPosition.lastPage,
                                          ),
                                    icon: const Icon(Icons.skip_previous),
                                    label: const Text('前の話'),
                                  ),
                                ),
                                if (episodeLabel != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      episodeLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: data.nextEpisodeNo == null
                                        ? null
                                        : () => _openEpisode(
                                            episodeNo: data.nextEpisodeNo!,
                                            episodeUrl: data.page.nextUrl,
                                            startPosition:
                                                _EpisodeStartPosition.firstPage,
                                          ),
                                    icon: const Icon(Icons.skip_next),
                                    label: const Text('次の話'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(
    BuildContext context,
    Object error,
    NarouEpisodeReaderRequest request,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('本文の取得に失敗しました。'),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(narouEpisodeReaderProvider(request)),
                  child: const Text('再試行'),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('戻る'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(
    KumihanTapDetails details,
    KumihanTapActions actions,
  ) async {
    final x = details.normalizedX;
    if (x <= 1 / 3) {
      await _handleSideTap(details, actions, KumihanTapSide.left);
      return;
    }
    if (x >= 2 / 3) {
      await _handleSideTap(details, actions, KumihanTapSide.right);
      return;
    }
    _toggleControls();
  }

  Future<void> _handleSideTap(
    KumihanTapDetails details,
    KumihanTapActions actions,
    KumihanTapSide side,
  ) async {
    final data = _latestData;
    final isForward = switch (details.snapshot.writingMode) {
      KumihanWritingMode.vertical => side == KumihanTapSide.left,
      KumihanWritingMode.horizontal => side == KumihanTapSide.right,
    };
    final isAtEdge = isForward
        ? details.snapshot.currentPage >= details.snapshot.totalPages - 1
        : details.snapshot.currentPage <= 0;

    if (data != null && isAtEdge) {
      if (isForward && data.nextEpisodeNo != null) {
        _openEpisode(
          episodeNo: data.nextEpisodeNo!,
          episodeUrl: data.page.nextUrl,
          startPosition: _EpisodeStartPosition.firstPage,
        );
        return;
      }
      if (isForward) {
        context.pop();
        return;
      }
      if (!isForward && data.previousEpisodeNo != null) {
        _openEpisode(
          episodeNo: data.previousEpisodeNo!,
          episodeUrl: data.page.prevUrl,
          startPosition: _EpisodeStartPosition.lastPage,
        );
        return;
      }
    }

    await actions.pageTurnFromSide(side, details.snapshot);
  }

  void _openEpisode({
    required int episodeNo,
    required String? episodeUrl,
    required _EpisodeStartPosition startPosition,
  }) {
    _saveProgressDebounce?.cancel();
    setState(() {
      _currentEpisodeNo = episodeNo;
      _currentEpisodeUrl = episodeUrl;
      _controlsVisible = false;
      _nextStartPosition = startPosition;
      _latestData = null;
      _pendingRestorePosition = null;
      _documentConfigKey = null;
      _cachedDocument = null;
    });
    _applyFullscreenMode();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    _applyFullscreenMode();
  }

  void _applyFullscreenMode() {
    final mode = _controlsVisible
        ? SystemUiMode.edgeToEdge
        : SystemUiMode.immersiveSticky;
    SystemChrome.setEnabledSystemUIMode(mode);
  }

  void _handleSnapshotChanged({
    required NarouEpisodeReaderData data,
    required KumihanSnapshot snapshot,
  }) {
    if (snapshot.totalPages <= 0) {
      return;
    }

    if (_nextStartPosition == _EpisodeStartPosition.lastPage) {
      _nextStartPosition = _EpisodeStartPosition.firstPage;
      final lastPageIndex = snapshot.totalPages - 1;
      if (snapshot.currentPage != lastPageIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          unawaited(_kumihanController.showLastPage());
        });
        return;
      }
    }

    final pendingRestorePosition = _pendingRestorePosition;
    if (pendingRestorePosition != null) {
      _pendingRestorePosition = null;
      final targetPage = _restorePageNumber(
        savedPageNumber: pendingRestorePosition.pageNumber,
        savedPageCount: pendingRestorePosition.pageCount,
        currentPageCount: snapshot.totalPages,
      );
      final targetPageIndex = targetPage - 1;
      if (snapshot.currentPage != targetPageIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          unawaited(_kumihanController.showPage(targetPageIndex));
        });
        return;
      }
    }

    _scheduleProgressSave(data: data, snapshot: snapshot);
  }

  void _scheduleProgressSave({
    required NarouEpisodeReaderData data,
    required KumihanSnapshot snapshot,
  }) {
    _saveProgressDebounce?.cancel();
    final episodeNo = _currentEpisodeNo;
    final pageNumber = snapshot.currentPage + 1;
    final pageCount = snapshot.totalPages;
    final nextEpisodeNo = data.nextEpisodeNo;
    _saveProgressDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(
        ref
            .read(downloadStoreProvider)
            .saveReadingProgress(
              site: NovelSite.narou,
              novelId: widget.novelId,
              episodeNo: episodeNo,
              pageNumber: pageNumber,
              pageCount: pageCount,
              nextEpisodeNo: nextEpisodeNo,
            ),
      );
    });
  }

  int _restorePageNumber({
    required int savedPageNumber,
    required int savedPageCount,
    required int currentPageCount,
  }) {
    if (savedPageCount <= 0 || currentPageCount <= 0) {
      return 1;
    }

    final completedPages = savedPageNumber - 1;
    final safeCompletedPages =
        (completedPages * currentPageCount) ~/ savedPageCount;
    final restoredPage = safeCompletedPages + 1;
    return restoredPage.clamp(1, currentPageCount);
  }

  KumihanDocument _documentFor({
    required NarouEpisodeReaderData data,
    required ReaderSettings readerSettings,
  }) {
    final configKey = [
      widget.novelId,
      _currentEpisodeNo,
      readerSettings.showPreface,
      readerSettings.showAfterword,
    ].join(':');
    if (_documentConfigKey == configKey && _cachedDocument != null) {
      return _cachedDocument!;
    }

    final snapshot = _kumihanController.snapshot;
    if (_documentConfigKey != null &&
        _documentConfigKey != configKey &&
        snapshot.totalPages > 0) {
      _pendingRestorePosition = _PendingRestorePosition(
        pageNumber: snapshot.currentPage + 1,
        pageCount: snapshot.totalPages,
      );
    }

    final document = const NarouKumihanParser().parseEpisode(
      data.page,
      settings: readerSettings,
    );
    _documentConfigKey = configKey;
    _cachedDocument = document;
    return document;
  }

  void _syncReaderModes({
    required KumihanWritingMode desiredWritingMode,
    required KumihanSpreadMode desiredSpreadMode,
    required KumihanSnapshot snapshot,
  }) {
    if (snapshot.writingMode == desiredWritingMode &&
        snapshot.spreadMode == desiredSpreadMode) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      if (_kumihanController.snapshot.writingMode != desiredWritingMode) {
        await _kumihanController.toggleWritingMode();
      }
      if (_kumihanController.snapshot.spreadMode != desiredSpreadMode) {
        await _kumihanController.toggleSpread();
      }
    });
  }
}

enum _EpisodeStartPosition { firstPage, lastPage }

class _PendingRestorePosition {
  const _PendingRestorePosition({
    required this.pageNumber,
    required this.pageCount,
  });

  final int pageNumber;
  final int pageCount;
}
