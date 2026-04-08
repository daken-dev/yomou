import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
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
    expect(settings.reader.disableCenterShadow, isFalse);
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
        disableCenterShadow: true,
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
    expect(settings.reader.disableCenterShadow, isTrue);
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

  test('migrates reader_disable_center_shadow from version 8 schema', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'settings_store_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final dbPath = '${tempDir.path}/app.sqlite';
    final rawDb = sqlite.sqlite3.open(dbPath);
    rawDb.execute('PRAGMA user_version = 8');
    rawDb.execute('''
      CREATE TABLE app_settings (
        id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
        theme_mode TEXT NOT NULL DEFAULT 'system',
        open_home_novel_directly_in_reader INTEGER NOT NULL DEFAULT 1,
        reader_writing_mode TEXT NOT NULL DEFAULT 'vertical',
        reader_tap_pattern TEXT NOT NULL DEFAULT 'left_center_right',
        reader_use_paper_texture INTEGER NOT NULL DEFAULT 1,
        reader_paper_color TEXT NOT NULL DEFAULT 'washi',
        reader_font_size REAL NOT NULL DEFAULT 20,
        reader_top_ui_padding_top REAL NOT NULL DEFAULT 0,
        reader_top_ui_padding_bottom REAL NOT NULL DEFAULT 0,
        reader_top_ui_padding_left REAL NOT NULL DEFAULT 0,
        reader_top_ui_padding_right REAL NOT NULL DEFAULT 0,
        reader_body_padding_top REAL NOT NULL DEFAULT 16,
        reader_body_padding_inner REAL NOT NULL DEFAULT 16,
        reader_body_padding_outer REAL NOT NULL DEFAULT 16,
        reader_body_padding_bottom REAL NOT NULL DEFAULT 16,
        reader_bottom_ui_padding_top REAL NOT NULL DEFAULT 0,
        reader_bottom_ui_padding_bottom REAL NOT NULL DEFAULT 0,
        reader_bottom_ui_padding_left REAL NOT NULL DEFAULT 0,
        reader_bottom_ui_padding_right REAL NOT NULL DEFAULT 0,
        reader_landscape_double_page INTEGER NOT NULL DEFAULT 1,
        reader_page_turn_animation_enabled INTEGER NOT NULL DEFAULT 1,
        reader_single_page_position TEXT NOT NULL DEFAULT 'center',
        reader_avoid_notch INTEGER NOT NULL DEFAULT 0,
        reader_show_preface INTEGER NOT NULL DEFAULT 1,
        reader_show_afterword INTEGER NOT NULL DEFAULT 1
      )
    ''');
    rawDb.execute('''
      INSERT INTO app_settings (
        id,
        theme_mode,
        open_home_novel_directly_in_reader,
        reader_writing_mode,
        reader_tap_pattern,
        reader_use_paper_texture,
        reader_paper_color,
        reader_font_size,
        reader_top_ui_padding_top,
        reader_top_ui_padding_bottom,
        reader_top_ui_padding_left,
        reader_top_ui_padding_right,
        reader_body_padding_top,
        reader_body_padding_inner,
        reader_body_padding_outer,
        reader_body_padding_bottom,
        reader_bottom_ui_padding_top,
        reader_bottom_ui_padding_bottom,
        reader_bottom_ui_padding_left,
        reader_bottom_ui_padding_right,
        reader_landscape_double_page,
        reader_page_turn_animation_enabled,
        reader_single_page_position,
        reader_avoid_notch,
        reader_show_preface,
        reader_show_afterword
      ) VALUES (
        1,
        'dark',
        1,
        'vertical',
        'left_center_right',
        1,
        'washi',
        20,
        0,
        0,
        0,
        0,
        16,
        16,
        16,
        16,
        0,
        0,
        0,
        0,
        1,
        1,
        'center',
        0,
        1,
        1
      )
    ''');
    rawDb.close();

    final database = AppDatabase(pathProvider: () async => dbPath);
    addTearDown(database.dispose);
    final store = SettingsStore(database);

    final settings = await store.readSettings();
    expect(settings.reader.disableCenterShadow, isFalse);

    await store.saveSettings(
      settings.copyWith(
        reader: settings.reader.copyWith(disableCenterShadow: true),
      ),
    );

    final updated = await store.readSettings();
    expect(updated.reader.disableCenterShadow, isTrue);
  });
}
