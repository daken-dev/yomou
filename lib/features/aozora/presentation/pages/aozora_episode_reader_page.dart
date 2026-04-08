import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kumihan/kumihan.dart' as kumi;
import 'package:yomou/features/aozora/application/aozora_episode_reader_controller.dart';
import 'package:yomou/features/aozora/data/aozora_episode_image_loader.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/data/download_store.dart';
import 'package:yomou/features/narou/presentation/reader_navigation.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/presentation/external_novel_page_launcher.dart';
import 'package:yomou/features/settings/application/settings_providers.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class AozoraEpisodeReaderPage extends ConsumerStatefulWidget {
  const AozoraEpisodeReaderPage({
    super.key,
    required this.novelId,
    this.textZipUrl,
    this.title,
    this.author,
    this.resumePage,
    this.resumePageCount,
  });

  final String novelId;
  final String? textZipUrl;
  final String? title;
  final String? author;
  final int? resumePage;
  final int? resumePageCount;

  @override
  ConsumerState<AozoraEpisodeReaderPage> createState() =>
      _AozoraEpisodeReaderPageState();
}

class _AozoraEpisodeReaderPageState
    extends ConsumerState<AozoraEpisodeReaderPage> {
  final kumi.KumihanController _controller = kumi.KumihanController();
  late final DownloadStore _downloadStore;
  Timer? _saveProgressDebounce;
  var _controlsVisible = false;
  _PendingRestorePosition? _pendingRestorePosition;
  kumi.KumihanSnapshot? _latestSnapshot;
  kumi.Document? _cachedDocument;
  Map<String, Uint8List>? _cachedImages;
  Future<ui.Image?> Function(String)? _cachedImageLoader;

  @override
  void initState() {
    super.initState();
    _downloadStore = ref.read(downloadStoreProvider);
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
    _flushProgressSave();
    _saveProgressDebounce?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = AozoraEpisodeReaderRequest(
      novelId: widget.novelId,
      textZipUrl: widget.textZipUrl,
      fallbackTitle: widget.title,
      fallbackAuthor: widget.author,
    );
    final episodeAsync = ref.watch(aozoraEpisodeReaderProvider(request));

    final appSettingsAsync = ref.watch(appSettingsProvider);
    final appSettings = switch (appSettingsAsync) {
      AsyncData(:final value) => value,
      _ => const AppSettings.defaults(),
    };
    final readerSettings = appSettings.reader;
    final readerTheme = readerSettings.toKumihanTheme(
      paperTexture: const AssetImage('assets/paper_textures/03.jpg'),
    );
    final desiredSpreadMode = _spreadModeFor(
      context,
      readerSettings: readerSettings,
    );

    return Scaffold(
      backgroundColor: readerTheme.paperColor,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: episodeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('本文取得失敗: $error')),
          data: (data) {
            final imageLoader = _imageLoaderFor(data.images);
            final document = _documentFor(data);
            final isDarkReader =
                readerTheme.paperColor.computeLuminance() < 0.5;
            final overlayBase = isDarkReader ? Colors.white : Colors.black;
            final overlayFg = isDarkReader ? Colors.black : Colors.white;

            return Stack(
              children: [
                Positioned.fill(
                  child: kumi.KumihanBook(
                    controller: _controller,
                    document: document,
                    imageLoader: imageLoader,
                    spreadMode: desiredSpreadMode,
                    layout: readerSettings.buildBookLayout(
                      notchPadding: MediaQuery.viewPaddingOf(context).top,
                    ),
                    theme: readerTheme,
                    autoPageFlipDuration: const Duration(milliseconds: 320),
                    pageTurnAnimationEnabled:
                        readerSettings.pageTurnAnimationEnabled,
                    onLinkTap: (url) =>
                        unawaited(openExternalUrlInBrowser(context, url)),
                    onSnapshotChanged: (snapshot) =>
                        _handleSnapshotChanged(snapshot: snapshot),
                    tapActionResolver: (width, height, x, y) =>
                        _resolveTapAction(
                          pattern: readerSettings.tapPattern,
                          width: width,
                          height: height,
                          x: x,
                          y: y,
                        ),
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
                            child: Align(
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
                                    Expanded(
                                      child: Text(
                                        data.author == null
                                            ? data.title
                                            : '${data.title} / ${data.author}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: overlayFg,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          context.push('/settings/reader'),
                                      icon: Icon(
                                        Icons.settings,
                                        color: overlayFg,
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
                  ),
                ),
              ],
            );
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

  Future<void> _turnPage({
    required bool isForward,
    kumi.KumihanSnapshot? snapshot,
  }) async {
    final effectiveSnapshot = snapshot ?? _controller.snapshot;
    if (effectiveSnapshot.totalPages <= 0) {
      return;
    }

    final amount = _pageTurnAmount();
    final isEdge = isAtReaderTurnEdge(
      currentPage: effectiveSnapshot.currentPage,
      totalPages: effectiveSnapshot.totalPages,
      pageTurnAmount: amount,
      isForward: isForward,
    );
    if (isForward && isEdge) {
      _saveProgressNow(effectiveSnapshot);
      if (mounted) {
        context.pop();
      }
      return;
    }

    final currentPage = effectiveSnapshot.currentPage;
    final targetPage = isForward
        ? (currentPage + amount).clamp(0, effectiveSnapshot.totalPages - 1)
        : (currentPage - amount).clamp(0, effectiveSnapshot.totalPages - 1);
    await _controller.showPage(targetPage);
  }

  void _handleSnapshotChanged({required kumi.KumihanSnapshot snapshot}) {
    _latestSnapshot = snapshot;
    if (snapshot.totalPages <= 0) {
      return;
    }

    final pendingRestorePosition = _pendingRestorePosition;
    if (pendingRestorePosition != null) {
      _pendingRestorePosition = null;
      final restoredPage = _restorePageNumber(
        savedPageNumber: pendingRestorePosition.pageNumber,
        savedPageCount: pendingRestorePosition.pageCount,
        currentPageCount: snapshot.totalPages,
      );
      final pageIndex = restoredPage - 1;
      if (pageIndex != snapshot.currentPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          unawaited(_controller.showPage(pageIndex));
        });
        return;
      }
    }

    _scheduleProgressSave(snapshot);
  }

  void _scheduleProgressSave(kumi.KumihanSnapshot snapshot) {
    _saveProgressDebounce?.cancel();
    _saveProgressDebounce = Timer(const Duration(milliseconds: 250), () {
      _saveProgressNow(snapshot);
    });
  }

  void _saveProgressNow(kumi.KumihanSnapshot snapshot) {
    unawaited(
      _downloadStore.saveReadingProgress(
        site: NovelSite.aozora,
        novelId: widget.novelId,
        episodeNo: 1,
        pageNumber: snapshot.currentPage + 1,
        pageCount: snapshot.totalPages,
      ),
    );
  }

  void _flushProgressSave() {
    final snapshot = _latestSnapshot;
    if (snapshot == null || snapshot.totalPages <= 0) {
      return;
    }
    _saveProgressNow(snapshot);
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
    return (safeCompletedPages + 1).clamp(1, currentPageCount);
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

  kumi.Document _documentFor(AozoraEpisodeReaderData data) {
    if (_cachedDocument != null) {
      return _cachedDocument!;
    }
    final document = kumi.AozoraParser(
      title: data.title,
      author: data.author,
      headerTitle: data.author == null
          ? data.title
          : '${data.title} / ${data.author}',
    ).parse(data.body);
    _cachedDocument = document;
    return document;
  }

  Future<ui.Image?> Function(String) _imageLoaderFor(
    Map<String, Uint8List> images,
  ) {
    if (_cachedImages == images && _cachedImageLoader != null) {
      return _cachedImageLoader!;
    }

    final imageLoader = AozoraEpisodeImageLoader(images).loadImage;
    _cachedImages = images;
    _cachedImageLoader = imageLoader;
    return imageLoader;
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
}

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

class _PendingRestorePosition {
  const _PendingRestorePosition({
    required this.pageNumber,
    required this.pageCount,
  });

  final int pageNumber;
  final int pageCount;
}
