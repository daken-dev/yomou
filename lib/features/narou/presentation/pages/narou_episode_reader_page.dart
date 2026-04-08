import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kumihan/kumihan.dart' as kumi;
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/narou/application/narou_episode_reader_controller.dart';
import 'package:yomou/features/narou/data/narou_episode_image_cache.dart';
import 'package:yomou/features/narou/data/narou_kumihan_parser.dart';
import 'package:yomou/features/narou/presentation/reader_navigation.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/presentation/external_novel_page_launcher.dart';
import 'package:yomou/features/settings/application/settings_providers.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class NarouEpisodeReaderPage extends ConsumerStatefulWidget {
  const NarouEpisodeReaderPage({
    super.key,
    required this.site,
    required this.novelId,
    required this.episodeNo,
    this.episodeUrl,
    this.resumePage,
    this.resumePageCount,
  });

  final NovelSite site;
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
  static const int _prefetchRemainingPagesThreshold = 4;

  final kumi.KumihanController _kumihanController = kumi.KumihanController();

  late int _currentEpisodeNo;
  late String? _currentEpisodeUrl;
  var _controlsVisible = false;
  var _nextStartPosition = _EpisodeStartPosition.firstPage;
  NarouEpisodeReaderData? _latestData;
  _PendingRestorePosition? _pendingRestorePosition;
  Timer? _saveProgressDebounce;
  String? _documentConfigKey;
  kumi.Document? _cachedDocument;
  NarouEpisodeReaderData? _currentEpisodeOverride;
  Future<NarouEpisodeReaderData>? _currentEpisodeOverrideFuture;
  NarouEpisodeReaderRequest? _prefetchRequest;
  Future<NarouEpisodeReaderData>? _prefetchFuture;
  NarouEpisodeReaderData? _prefetchedEpisodeData;
  Object? _prefetchToken;

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
    _clearCurrentEpisodeOverride();
    _clearPrefetchState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = NarouEpisodeReaderRequest(
      site: widget.site,
      novelId: widget.novelId,
      episodeNo: _currentEpisodeNo,
      episodeUrl: _currentEpisodeUrl,
    );
    final episodeAsync = _currentEpisodeOverride != null
        ? AsyncData<NarouEpisodeReaderData>(_currentEpisodeOverride!)
        : _currentEpisodeOverrideFuture == null
        ? ref.watch(narouEpisodeReaderProvider(request))
        : null;
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
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: episodeAsync != null
            ? switch (episodeAsync) {
                AsyncData(:final value) => _buildReader(
                  context,
                  data: value,
                  imageLoader: imageLoader,
                  snapshot: snapshot,
                  readerSettings: readerSettings,
                  readerTheme: readerTheme,
                ),
                AsyncError(:final error) => _buildError(
                  context,
                  error,
                  request,
                ),
                _ => const Center(child: CircularProgressIndicator()),
              }
            : FutureBuilder<NarouEpisodeReaderData>(
                future: _currentEpisodeOverrideFuture,
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.hasData) {
                    return _buildReader(
                      context,
                      data: futureSnapshot.data!,
                      imageLoader: imageLoader,
                      snapshot: snapshot,
                      readerSettings: readerSettings,
                      readerTheme: readerTheme,
                    );
                  }
                  if (futureSnapshot.hasError) {
                    return _buildError(
                      context,
                      futureSnapshot.error!,
                      request,
                      onRetry: () {
                        setState(() {
                          _clearCurrentEpisodeOverride();
                        });
                        ref.invalidate(narouEpisodeReaderProvider(request));
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _controlsVisible) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.arrowRight) {
      unawaited(_turnPage(isForward: true));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.arrowLeft) {
      unawaited(_turnPage(isForward: false));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildReader(
    BuildContext context, {
    required NarouEpisodeReaderData data,
    required Future<ui.Image?> Function(String) imageLoader,
    required kumi.KumihanSnapshot snapshot,
    required ReaderSettings readerSettings,
    required kumi.KumihanThemeData readerTheme,
  }) {
    _latestData = data;
    final isDarkReader = readerTheme.paperColor.computeLuminance() < 0.5;
    final overlayBase = isDarkReader ? Colors.white : Colors.black;
    final overlayFg = isDarkReader ? Colors.black : Colors.white;
    final overlayFgDim = isDarkReader ? Colors.black54 : Colors.white70;
    final document = _documentFor(data: data, readerSettings: readerSettings);
    final desiredSpreadMode = _spreadModeFor(
      context,
      readerSettings: readerSettings,
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
          child: kumi.KumihanBook(
            key: ValueKey<String>(
              '${widget.novelId}:$_currentEpisodeNo:${_currentEpisodeUrl ?? ''}',
            ),
            controller: _kumihanController,
            document: document,
            imageLoader: imageLoader,
            baseUri: Uri.tryParse(data.page.url),
            spreadMode: desiredSpreadMode,
            layout: readerSettings.buildBookLayout(
              notchPadding: MediaQuery.viewPaddingOf(context).top,
            ),
            theme: readerTheme,
            autoPageFlipDuration: const Duration(milliseconds: 320),
            pageTurnAnimationEnabled: readerSettings.pageTurnAnimationEnabled,
            onLinkTap: (url) =>
                unawaited(openExternalUrlInBrowser(context, url)),
            tapActionResolver: (width, height, x, y) => _resolveTapAction(
              pattern: readerSettings.tapPattern,
              width: width,
              height: height,
              x: x,
              y: y,
            ),
            onSnapshotChanged: (snapshot) =>
                _handleSnapshotChanged(data: data, snapshot: snapshot),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _controlsVisible,
            child: _ReaderCenterTapRegion(
              pattern: readerSettings.tapPattern,
              onTap: _toggleControls,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _controlsVisible ? 1 : 0,
              child: ColoredBox(
                color: overlayBase.withValues(alpha: 0.14),
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
                              color: overlayBase.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.pop(),
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: overlayFg,
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
                                        style: TextStyle(
                                          color: overlayFgDim,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        pageTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: overlayFg,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: snapshot.totalPages > 0
                                      ? () => _showPageJumpDialog(
                                          context,
                                          currentPage: snapshot.currentPage + 1,
                                          totalPages: snapshot.totalPages,
                                        )
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: overlayFg.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pageLabel,
                                      style: TextStyle(
                                        color: overlayFg,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      context.push('/settings/reader'),
                                  icon: Icon(Icons.settings, color: overlayFg),
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
                              color: overlayBase.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
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
                                    icon: const Icon(Icons.skip_previous),
                                    label: const Text('次の話'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: overlayFg,
                                    ),
                                  ),
                                ),
                                if (episodeLabel != null)
                                  GestureDetector(
                                    onTap: () => _showEpisodeJumpDialog(
                                      context,
                                      currentEpisode:
                                          data.page.sequenceCurrent!,
                                      totalEpisodes: data.page.sequenceTotal!,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: overlayFg.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        episodeLabel,
                                        style: TextStyle(
                                          color: overlayFg,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
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
                                    iconAlignment: IconAlignment.end,
                                    icon: const Icon(Icons.skip_next),
                                    label: const Text('前の話'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: overlayFg,
                                    ),
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
    NarouEpisodeReaderRequest request, {
    VoidCallback? onRetry,
  }) {
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
                  onPressed:
                      onRetry ??
                      () => ref.invalidate(narouEpisodeReaderProvider(request)),
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

  Future<void> _turnPage({
    required bool isForward,
    kumi.KumihanSnapshot? snapshot,
  }) async {
    final data = _latestData;
    final effectiveSnapshot = snapshot ?? _kumihanController.snapshot;
    if (effectiveSnapshot.totalPages <= 0) {
      return;
    }

    final amount = _pageTurnAmount();
    final isAtEdge = isAtReaderTurnEdge(
      currentPage: effectiveSnapshot.currentPage,
      totalPages: effectiveSnapshot.totalPages,
      pageTurnAmount: amount,
      isForward: isForward,
    );

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

    final currentPage = effectiveSnapshot.currentPage;
    final targetPage = isForward
        ? (currentPage + amount).clamp(0, effectiveSnapshot.totalPages - 1)
        : (currentPage - amount).clamp(0, effectiveSnapshot.totalPages - 1);
    await _kumihanController.showPage(targetPage);
  }

  void _openEpisode({
    required int episodeNo,
    required String? episodeUrl,
    required _EpisodeStartPosition startPosition,
  }) {
    _saveProgressDebounce?.cancel();
    final nextRequest = NarouEpisodeReaderRequest(
      site: widget.site,
      novelId: widget.novelId,
      episodeNo: episodeNo,
      episodeUrl: episodeUrl,
    );
    final shouldUsePrefetchedEpisode = _prefetchRequest == nextRequest;
    final currentOverride = shouldUsePrefetchedEpisode
        ? _prefetchedEpisodeData
        : null;
    final currentOverrideFuture =
        shouldUsePrefetchedEpisode && currentOverride == null
        ? _prefetchFuture
        : null;
    setState(() {
      _currentEpisodeNo = episodeNo;
      _currentEpisodeUrl = episodeUrl;
      _controlsVisible = false;
      _nextStartPosition = startPosition;
      _latestData = null;
      _pendingRestorePosition = null;
      _documentConfigKey = null;
      _cachedDocument = null;
      _currentEpisodeOverride = currentOverride;
      _currentEpisodeOverrideFuture = currentOverrideFuture;
      _clearPrefetchState();
    });
    _applyFullscreenMode();
  }

  void _showPageJumpDialog(
    BuildContext context, {
    required int currentPage,
    required int totalPages,
  }) {
    showDialog<int>(
      context: context,
      builder: (context) => _EpisodeReaderNumberInputDialog(
        title: 'ページ移動',
        labelText: 'ページ番号',
        suffixTotal: totalPages,
        initialValue: currentPage,
      ),
    ).then((page) {
      if (page != null && mounted) {
        setState(() {
          _controlsVisible = false;
        });
        _applyFullscreenMode();
        unawaited(_kumihanController.showPage(page - 1));
      }
    });
  }

  void _showEpisodeJumpDialog(
    BuildContext context, {
    required int currentEpisode,
    required int totalEpisodes,
  }) {
    showDialog<int>(
      context: context,
      builder: (context) => _EpisodeReaderNumberInputDialog(
        title: '話数移動',
        labelText: '話数',
        suffixTotal: totalEpisodes,
        initialValue: currentEpisode,
      ),
    ).then((episode) {
      if (episode != null && episode != currentEpisode) {
        _openEpisode(
          episodeNo: episode,
          episodeUrl: null,
          startPosition: _EpisodeStartPosition.firstPage,
        );
      }
    });
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
    required kumi.KumihanSnapshot snapshot,
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

    _maybePrefetchNextEpisode(data: data, snapshot: snapshot);
    _scheduleProgressSave(data: data, snapshot: snapshot);
  }

  void _maybePrefetchNextEpisode({
    required NarouEpisodeReaderData data,
    required kumi.KumihanSnapshot snapshot,
  }) {
    final nextEpisodeNo = data.nextEpisodeNo;
    if (nextEpisodeNo == null) {
      _clearPrefetchState();
      return;
    }

    final remainingPages = snapshot.totalPages - snapshot.currentPage - 1;
    if (remainingPages > _prefetchRemainingPagesThreshold) {
      return;
    }

    final request = NarouEpisodeReaderRequest(
      site: widget.site,
      novelId: widget.novelId,
      episodeNo: nextEpisodeNo,
      episodeUrl: data.page.nextUrl,
    );
    if (_prefetchRequest == request) {
      return;
    }

    _startPrefetch(request);
  }

  void _startPrefetch(NarouEpisodeReaderRequest request) {
    final token = Object();
    final future = fetchNarouEpisodeReaderDataWithWidgetRef(ref, request);
    _prefetchToken = token;
    _prefetchRequest = request;
    _prefetchFuture = future;
    _prefetchedEpisodeData = null;
    future.then(
      (data) {
        if (!identical(_prefetchToken, token)) {
          return;
        }
        _prefetchedEpisodeData = data;
      },
      onError: (_) {
        if (!identical(_prefetchToken, token)) {
          return;
        }
        _clearPrefetchState();
      },
    );
  }

  void _scheduleProgressSave({
    required NarouEpisodeReaderData data,
    required kumi.KumihanSnapshot snapshot,
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
              site: widget.site,
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

  kumi.Document _documentFor({
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

  int _pageTurnAmount() {
    final appSettings = switch (ref.read(appSettingsProvider)) {
      AsyncData(:final value) => value,
      _ => const AppSettings.defaults(),
    };
    return _spreadModeFor(context, readerSettings: appSettings.reader) ==
            kumi.KumihanSpreadMode.doublePage
        ? 2
        : 1;
  }

  kumi.KumihanSpreadMode _spreadModeFor(
    BuildContext context, {
    required ReaderSettings readerSettings,
  }) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return readerSettings.enableLandscapeDoublePage && isLandscape
        ? kumi.KumihanSpreadMode.doublePage
        : kumi.KumihanSpreadMode.single;
  }

  kumi.PageFlipTapAction? _resolveTapAction({
    required ReaderTapPattern pattern,
    required double width,
    required double height,
    required double x,
    required double y,
  }) {
    final action = resolveReaderTapAction(
      pattern: pattern,
      normalizedX: width == 0 ? 0.5 : x / width,
      normalizedY: height == 0 ? 0.5 : y / height,
    );
    return switch (action) {
      ReaderTapAction.backward => kumi.PageFlipTapAction.back,
      ReaderTapAction.forward => kumi.PageFlipTapAction.next,
      ReaderTapAction.toggleControls => null,
    };
  }

  void _clearCurrentEpisodeOverride() {
    _currentEpisodeOverride = null;
    _currentEpisodeOverrideFuture = null;
  }

  void _clearPrefetchState() {
    _prefetchToken = null;
    _prefetchRequest = null;
    _prefetchFuture = null;
    _prefetchedEpisodeData = null;
  }
}

enum _EpisodeStartPosition { firstPage, lastPage }

class _ReaderCenterTapRegion extends StatelessWidget {
  const _ReaderCenterTapRegion({required this.pattern, required this.onTap});

  final ReaderTapPattern pattern;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return switch (pattern) {
      ReaderTapPattern.leftCenterRight => Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: 1 / 3,
          heightFactor: 1,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: const SizedBox.expand(),
          ),
        ),
      ),
      ReaderTapPattern.topCenterBottom => Align(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: 1,
          heightFactor: 1 / 3,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    };
  }
}

class _EpisodeReaderNumberInputDialog extends StatefulWidget {
  const _EpisodeReaderNumberInputDialog({
    required this.title,
    required this.labelText,
    required this.suffixTotal,
    required this.initialValue,
  });

  final String title;
  final String labelText;
  final int suffixTotal;
  final int initialValue;

  @override
  State<_EpisodeReaderNumberInputDialog> createState() =>
      _EpisodeReaderNumberInputDialogState();
}

class _EpisodeReaderNumberInputDialogState
    extends State<_EpisodeReaderNumberInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitIfValid() {
    final value = int.tryParse(_controller.text);
    if (value != null && value >= 1 && value <= widget.suffixTotal) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: '1 〜 ${widget.suffixTotal}',
          suffixText: '/ ${widget.suffixTotal}',
        ),
        onSubmitted: (_) => _submitIfValid(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(onPressed: _submitIfValid, child: const Text('移動')),
      ],
    );
  }
}

class _PendingRestorePosition {
  const _PendingRestorePosition({
    required this.pageNumber,
    required this.pageCount,
  });

  final int pageNumber;
  final int pageCount;
}
