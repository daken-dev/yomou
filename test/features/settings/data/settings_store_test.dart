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
        pageMarginScale: 0.9,
        enableLandscapeDoublePage: false,
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
    expect(settings.reader.pageMarginScale, 0.9);
    expect(settings.reader.enableLandscapeDoublePage, isFalse);
    expect(settings.reader.showPreface, isFalse);
    expect(settings.reader.showAfterword, isFalse);
  });
}
