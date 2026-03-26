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
  KumihanWritingMode get kumihanValue {
    return switch (this) {
      ReaderWritingMode.vertical => KumihanWritingMode.vertical,
      ReaderWritingMode.horizontal => KumihanWritingMode.horizontal,
    };
  }

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
      ReaderSinglePagePosition.center =>
        KumihanSinglePageNumberPosition.center,
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
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingLeft,
    required this.paddingRight,
    required this.enableLandscapeDoublePage,
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
      paddingTop = 16,
      paddingBottom = 16,
      paddingLeft = 16,
      paddingRight = 16,
      enableLandscapeDoublePage = true,
      singlePagePosition = ReaderSinglePagePosition.center,
      avoidNotch = false,
      showPreface = true,
      showAfterword = true;

  final ReaderWritingMode writingMode;
  final ReaderTapPattern tapPattern;
  final bool usePaperTexture;
  final ReaderPaperColorPreset paperColorPreset;
  final double fontSize;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final bool enableLandscapeDoublePage;
  final ReaderSinglePagePosition singlePagePosition;
  final bool avoidNotch;
  final bool showPreface;
  final bool showAfterword;

  KumihanLayoutData buildLayout({double notchPadding = 0}) {
    final effectiveTop = paddingTop + (avoidNotch ? notchPadding : 0);
    return KumihanLayoutData(
      fontSize: fontSize,
      pagePadding: EdgeInsets.fromLTRB(
        paddingLeft,
        effectiveTop,
        paddingRight,
        paddingBottom,
      ),
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
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
    bool? enableLandscapeDoublePage,
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
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
      enableLandscapeDoublePage:
          enableLandscapeDoublePage ?? this.enableLandscapeDoublePage,
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
