import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/core/database/app_database.dart';
import 'package:yomou/features/settings/data/settings_store.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

void main() {
  test('readSettings returns defaults when no row exists', () async {
    final database = AppDatabase(pathProvider: () async => ':memory:');
    addTearDown(database.dispose);

    final store = SettingsStore(database);
    final settings = await store.readSettings();

    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.openHomeNovelDirectlyInReader, isTrue);
    expect(settings.reader.writingMode, ReaderWritingMode.vertical);
    expect(settings.reader.tapPattern, ReaderTapPattern.leftCenterRight);
    expect(settings.reader.usePaperTexture, isTrue);
    expect(settings.reader.paperColorPreset, ReaderPaperColorPreset.washi);
    expect(settings.reader.showPreface, isTrue);
    expect(settings.reader.showAfterword, isTrue);
  });

  test('saveSettings persists app and reader preferences', () async {
    final database = AppDatabase(pathProvider: () async => ':memory:');
    addTearDown(database.dispose);

    final store = SettingsStore(database);
    final settingsToSave = const AppSettings.defaults().copyWith(
      themeMode: AppThemeMode.dark,
      openHomeNovelDirectlyInReader: false,
      reader: const ReaderSettings.defaults().copyWith(
        writingMode: ReaderWritingMode.horizontal,
        tapPattern: ReaderTapPattern.topCenterBottom,
        usePaperTexture: false,
        paperColorPreset: ReaderPaperColorPreset.dark,
        fontSize: 24,
        topUiPaddingTop: 4,
        topUiPaddingBottom: 8,
        topUiPaddingLeft: 12,
        topUiPaddingRight: 16,
        bodyPaddingTop: 20,
        bodyPaddingInner: 8,
        bodyPaddingOuter: 12,
        bodyPaddingBottom: 24,
        bottomUiPaddingTop: 3,
        bottomUiPaddingBottom: 5,
        bottomUiPaddingLeft: 7,
        bottomUiPaddingRight: 9,
        enableLandscapeDoublePage: false,
        pageTurnAnimationEnabled: false,
        singlePagePosition: ReaderSinglePagePosition.right,
        avoidNotch: true,
        showPreface: false,
        showAfterword: false,
      ),
    );
    await store.saveSettings(settingsToSave);

    final settings = await store.readSettings();
    expect(settings.themeMode, AppThemeMode.dark);
    expect(settings.openHomeNovelDirectlyInReader, isFalse);
    expect(settings.reader.writingMode, ReaderWritingMode.horizontal);
    expect(settings.reader.tapPattern, ReaderTapPattern.topCenterBottom);
    expect(settings.reader.usePaperTexture, isFalse);
    expect(settings.reader.paperColorPreset, ReaderPaperColorPreset.dark);
    expect(settings.reader.fontSize, 24);
    expect(settings.reader.topUiPaddingTop, 4);
    expect(settings.reader.topUiPaddingBottom, 8);
    expect(settings.reader.topUiPaddingLeft, 12);
    expect(settings.reader.topUiPaddingRight, 16);
    expect(settings.reader.bodyPaddingTop, 20);
    expect(settings.reader.bodyPaddingInner, 8);
    expect(settings.reader.bodyPaddingOuter, 12);
    expect(settings.reader.bodyPaddingBottom, 24);
    expect(settings.reader.bottomUiPaddingTop, 3);
    expect(settings.reader.bottomUiPaddingBottom, 5);
    expect(settings.reader.bottomUiPaddingLeft, 7);
    expect(settings.reader.bottomUiPaddingRight, 9);
    expect(settings.reader.enableLandscapeDoublePage, isFalse);
    expect(settings.reader.pageTurnAnimationEnabled, isFalse);
    expect(settings.reader.singlePagePosition, ReaderSinglePagePosition.right);
    expect(settings.reader.avoidNotch, isTrue);
    expect(settings.reader.showPreface, isFalse);
    expect(settings.reader.showAfterword, isFalse);
  });
}
