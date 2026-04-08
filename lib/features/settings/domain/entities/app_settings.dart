import 'package:flutter/material.dart';
import 'package:kumihan/kumihan.dart';

enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  ThemeMode get themeMode {
    return switch (this) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }

  String get storageValue {
    return switch (this) {
      AppThemeMode.system => 'system',
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
    };
  }

  String get label {
    return switch (this) {
      AppThemeMode.system => 'システム',
      AppThemeMode.light => 'ライト',
      AppThemeMode.dark => 'ダーク',
    };
  }

  static AppThemeMode fromStorageValue(String? value) {
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }
}

enum ReaderWritingMode { vertical, horizontal }

extension ReaderWritingModeX on ReaderWritingMode {
  String get storageValue {
    return switch (this) {
      ReaderWritingMode.vertical => 'vertical',
      ReaderWritingMode.horizontal => 'horizontal',
    };
  }

  String get label {
    return switch (this) {
      ReaderWritingMode.vertical => '縦',
      ReaderWritingMode.horizontal => '横',
    };
  }

  static ReaderWritingMode fromStorageValue(String? value) {
    return switch (value) {
      'horizontal' => ReaderWritingMode.horizontal,
      _ => ReaderWritingMode.vertical,
    };
  }
}

enum ReaderPaperColorPreset { white, washi, dark }

extension ReaderPaperColorPresetX on ReaderPaperColorPreset {
  String get storageValue {
    return switch (this) {
      ReaderPaperColorPreset.white => 'white',
      ReaderPaperColorPreset.washi => 'washi',
      ReaderPaperColorPreset.dark => 'dark',
    };
  }

  String get label {
    return switch (this) {
      ReaderPaperColorPreset.white => '白',
      ReaderPaperColorPreset.washi => '和紙',
      ReaderPaperColorPreset.dark => 'ダーク',
    };
  }

  static ReaderPaperColorPreset fromStorageValue(String? value) {
    return switch (value) {
      'white' => ReaderPaperColorPreset.white,
      'dark' => ReaderPaperColorPreset.dark,
      _ => ReaderPaperColorPreset.washi,
    };
  }
}

enum ReaderTapPattern { leftCenterRight, topCenterBottom }

extension ReaderTapPatternX on ReaderTapPattern {
  String get storageValue {
    return switch (this) {
      ReaderTapPattern.leftCenterRight => 'left_center_right',
      ReaderTapPattern.topCenterBottom => 'top_center_bottom',
    };
  }

  String get label {
    return switch (this) {
      ReaderTapPattern.leftCenterRight => '左中右',
      ReaderTapPattern.topCenterBottom => '上中下',
    };
  }

  static ReaderTapPattern fromStorageValue(String? value) {
    return switch (value) {
      'top_center_bottom' => ReaderTapPattern.topCenterBottom,
      _ => ReaderTapPattern.leftCenterRight,
    };
  }
}

enum ReaderSinglePagePosition { left, center, right }

extension ReaderSinglePagePositionX on ReaderSinglePagePosition {
  KumihanSinglePageNumberPosition get kumihanValue {
    return switch (this) {
      ReaderSinglePagePosition.left => KumihanSinglePageNumberPosition.left,
      ReaderSinglePagePosition.center => KumihanSinglePageNumberPosition.center,
      ReaderSinglePagePosition.right => KumihanSinglePageNumberPosition.right,
    };
  }

  String get storageValue {
    return switch (this) {
      ReaderSinglePagePosition.left => 'left',
      ReaderSinglePagePosition.center => 'center',
      ReaderSinglePagePosition.right => 'right',
    };
  }

  String get label {
    return switch (this) {
      ReaderSinglePagePosition.left => '左',
      ReaderSinglePagePosition.center => '中央',
      ReaderSinglePagePosition.right => '右',
    };
  }

  static ReaderSinglePagePosition fromStorageValue(String? value) {
    return switch (value) {
      'left' => ReaderSinglePagePosition.left,
      'right' => ReaderSinglePagePosition.right,
      _ => ReaderSinglePagePosition.center,
    };
  }
}

class ReaderSettings {
  const ReaderSettings({
    required this.writingMode,
    required this.tapPattern,
    required this.usePaperTexture,
    required this.paperColorPreset,
    required this.fontSize,
    required this.topUiPaddingTop,
    required this.topUiPaddingBottom,
    required this.topUiPaddingLeft,
    required this.topUiPaddingRight,
    required this.bodyPaddingTop,
    required this.bodyPaddingInner,
    required this.bodyPaddingOuter,
    required this.bodyPaddingBottom,
    required this.bottomUiPaddingTop,
    required this.bottomUiPaddingBottom,
    required this.bottomUiPaddingLeft,
    required this.bottomUiPaddingRight,
    required this.enableLandscapeDoublePage,
    required this.pageTurnAnimationEnabled,
    required this.singlePagePosition,
    required this.avoidNotch,
    required this.showPreface,
    required this.showAfterword,
  });

  const ReaderSettings.defaults()
    : writingMode = ReaderWritingMode.vertical,
      tapPattern = ReaderTapPattern.leftCenterRight,
      usePaperTexture = true,
      paperColorPreset = ReaderPaperColorPreset.washi,
      fontSize = 20,
      topUiPaddingTop = 0,
      topUiPaddingBottom = 0,
      topUiPaddingLeft = 0,
      topUiPaddingRight = 0,
      bodyPaddingTop = 16,
      bodyPaddingInner = 16,
      bodyPaddingOuter = 16,
      bodyPaddingBottom = 16,
      bottomUiPaddingTop = 0,
      bottomUiPaddingBottom = 0,
      bottomUiPaddingLeft = 0,
      bottomUiPaddingRight = 0,
      enableLandscapeDoublePage = true,
      pageTurnAnimationEnabled = true,
      singlePagePosition = ReaderSinglePagePosition.center,
      avoidNotch = false,
      showPreface = true,
      showAfterword = true;

  final ReaderWritingMode writingMode;
  final ReaderTapPattern tapPattern;
  final bool usePaperTexture;
  final ReaderPaperColorPreset paperColorPreset;
  final double fontSize;
  final double topUiPaddingTop;
  final double topUiPaddingBottom;
  final double topUiPaddingLeft;
  final double topUiPaddingRight;
  final double bodyPaddingTop;
  final double bodyPaddingInner;
  final double bodyPaddingOuter;
  final double bodyPaddingBottom;
  final double bottomUiPaddingTop;
  final double bottomUiPaddingBottom;
  final double bottomUiPaddingLeft;
  final double bottomUiPaddingRight;
  final bool enableLandscapeDoublePage;
  final bool pageTurnAnimationEnabled;
  final ReaderSinglePagePosition singlePagePosition;
  final bool avoidNotch;
  final bool showPreface;
  final bool showAfterword;

  EdgeInsets get topUiPadding => EdgeInsets.fromLTRB(
    topUiPaddingLeft,
    topUiPaddingTop,
    topUiPaddingRight,
    topUiPaddingBottom,
  );

  EdgeInsets get bottomUiPadding => EdgeInsets.fromLTRB(
    bottomUiPaddingLeft,
    bottomUiPaddingTop,
    bottomUiPaddingRight,
    bottomUiPaddingBottom,
  );

  KumihanBookBodyPadding get bodyPadding => KumihanBookBodyPadding(
    top: bodyPaddingTop,
    inner: bodyPaddingInner,
    outer: bodyPaddingOuter,
    bottom: bodyPaddingBottom,
  );

  KumihanBookLayoutData buildBookLayout({double notchPadding = 0}) {
    final effectiveTopUiPadding = topUiPadding.copyWith(
      top: topUiPadding.top + (avoidNotch ? notchPadding : 0),
    );
    return KumihanBookLayoutData(
      fontSize: fontSize,
      topUiPadding: effectiveTopUiPadding,
      bodyPadding: bodyPadding,
      bottomUiPadding: bottomUiPadding,
      singlePageNumberPosition: singlePagePosition.kumihanValue,
    );
  }

  KumihanThemeData toKumihanTheme({ImageProvider<Object>? paperTexture}) {
    final palette = switch (paperColorPreset) {
      ReaderPaperColorPreset.white => const _ReaderThemePalette(
        paperColor: Color(0xFFFDFDFD),
        textColor: Color(0xFF1C1C1C),
        captionColor: Color(0xFF5F6B66),
        rubyColor: Color(0xFF313131),
        linkColor: Color(0xFF2458D3),
        internalLinkColor: Color(0xFF0D8C6C),
      ),
      ReaderPaperColorPreset.washi => const _ReaderThemePalette(
        paperColor: Color(0xFFFFF7EA),
        textColor: Color(0xFF3F3227),
        captionColor: Color(0xFF6D8661),
        rubyColor: Color(0xFF4A392C),
        linkColor: Color(0xFF3B5BD6),
        internalLinkColor: Color(0xFF1F8A56),
      ),
      ReaderPaperColorPreset.dark => const _ReaderThemePalette(
        paperColor: Color(0xFF181411),
        textColor: Color(0xFFECE0CB),
        captionColor: Color(0xFF9FBDA7),
        rubyColor: Color(0xFFD9C8AE),
        linkColor: Color(0xFF8BBDFF),
        internalLinkColor: Color(0xFF7FD7A0),
      ),
    };

    return KumihanThemeData(
      paperColor: palette.paperColor,
      textColor: palette.textColor,
      captionColor: palette.captionColor,
      rubyColor: palette.rubyColor,
      linkColor: palette.linkColor,
      internalLinkColor: palette.internalLinkColor,
      paperTexture: usePaperTexture ? paperTexture : null,
      paperTextureOpacity: usePaperTexture ? 0.18 : 0,
    );
  }

  ReaderSettings copyWith({
    ReaderWritingMode? writingMode,
    ReaderTapPattern? tapPattern,
    bool? usePaperTexture,
    ReaderPaperColorPreset? paperColorPreset,
    double? fontSize,
    double? topUiPaddingTop,
    double? topUiPaddingBottom,
    double? topUiPaddingLeft,
    double? topUiPaddingRight,
    double? bodyPaddingTop,
    double? bodyPaddingInner,
    double? bodyPaddingOuter,
    double? bodyPaddingBottom,
    double? bottomUiPaddingTop,
    double? bottomUiPaddingBottom,
    double? bottomUiPaddingLeft,
    double? bottomUiPaddingRight,
    bool? enableLandscapeDoublePage,
    bool? pageTurnAnimationEnabled,
    ReaderSinglePagePosition? singlePagePosition,
    bool? avoidNotch,
    bool? showPreface,
    bool? showAfterword,
  }) {
    return ReaderSettings(
      writingMode: writingMode ?? this.writingMode,
      tapPattern: tapPattern ?? this.tapPattern,
      usePaperTexture: usePaperTexture ?? this.usePaperTexture,
      paperColorPreset: paperColorPreset ?? this.paperColorPreset,
      fontSize: fontSize ?? this.fontSize,
      topUiPaddingTop: topUiPaddingTop ?? this.topUiPaddingTop,
      topUiPaddingBottom: topUiPaddingBottom ?? this.topUiPaddingBottom,
      topUiPaddingLeft: topUiPaddingLeft ?? this.topUiPaddingLeft,
      topUiPaddingRight: topUiPaddingRight ?? this.topUiPaddingRight,
      bodyPaddingTop: bodyPaddingTop ?? this.bodyPaddingTop,
      bodyPaddingInner: bodyPaddingInner ?? this.bodyPaddingInner,
      bodyPaddingOuter: bodyPaddingOuter ?? this.bodyPaddingOuter,
      bodyPaddingBottom: bodyPaddingBottom ?? this.bodyPaddingBottom,
      bottomUiPaddingTop: bottomUiPaddingTop ?? this.bottomUiPaddingTop,
      bottomUiPaddingBottom:
          bottomUiPaddingBottom ?? this.bottomUiPaddingBottom,
      bottomUiPaddingLeft: bottomUiPaddingLeft ?? this.bottomUiPaddingLeft,
      bottomUiPaddingRight: bottomUiPaddingRight ?? this.bottomUiPaddingRight,
      enableLandscapeDoublePage:
          enableLandscapeDoublePage ?? this.enableLandscapeDoublePage,
      pageTurnAnimationEnabled:
          pageTurnAnimationEnabled ?? this.pageTurnAnimationEnabled,
      singlePagePosition: singlePagePosition ?? this.singlePagePosition,
      avoidNotch: avoidNotch ?? this.avoidNotch,
      showPreface: showPreface ?? this.showPreface,
      showAfterword: showAfterword ?? this.showAfterword,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.openHomeNovelDirectlyInReader,
    required this.reader,
  });

  const AppSettings.defaults()
    : themeMode = AppThemeMode.system,
      openHomeNovelDirectlyInReader = true,
      reader = const ReaderSettings.defaults();

  final AppThemeMode themeMode;
  final bool openHomeNovelDirectlyInReader;
  final ReaderSettings reader;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? openHomeNovelDirectlyInReader,
    ReaderSettings? reader,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      openHomeNovelDirectlyInReader:
          openHomeNovelDirectlyInReader ?? this.openHomeNovelDirectlyInReader,
      reader: reader ?? this.reader,
    );
  }
}

class _ReaderThemePalette {
  const _ReaderThemePalette({
    required this.paperColor,
    required this.textColor,
    required this.captionColor,
    required this.rubyColor,
    required this.linkColor,
    required this.internalLinkColor,
  });

  final Color paperColor;
  final Color textColor;
  final Color captionColor;
  final Color rubyColor;
  final Color linkColor;
  final Color internalLinkColor;
}
