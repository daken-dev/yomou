import 'dart:async';

import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:yomou/core/database/app_database.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class SettingsStore {
  SettingsStore(this._database);

  final AppDatabase _database;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  Stream<void> get changes => _changesController.stream;

  Future<AppSettings> readSettings() async {
    return _database.read((db) {
      final rows = db.select('SELECT * FROM app_settings WHERE id = 1 LIMIT 1');
      if (rows.isEmpty) {
        return const AppSettings.defaults();
      }
      return _appSettingsFromRow(rows.first);
    });
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _database.write((db) {
      db.execute(
        '''
        INSERT INTO app_settings (
          id,
          theme_mode,
          open_home_novel_directly_in_reader,
          reader_writing_mode,
          reader_tap_pattern,
          reader_use_paper_texture,
          reader_paper_color,
          reader_font_size,
          reader_padding_top,
          reader_padding_bottom,
          reader_padding_left,
          reader_padding_right,
          reader_landscape_double_page,
          reader_single_page_position,
          reader_avoid_notch,
          reader_show_preface,
          reader_show_afterword
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          theme_mode = excluded.theme_mode,
          open_home_novel_directly_in_reader =
              excluded.open_home_novel_directly_in_reader,
          reader_writing_mode = excluded.reader_writing_mode,
          reader_tap_pattern = excluded.reader_tap_pattern,
          reader_use_paper_texture = excluded.reader_use_paper_texture,
          reader_paper_color = excluded.reader_paper_color,
          reader_font_size = excluded.reader_font_size,
          reader_padding_top = excluded.reader_padding_top,
          reader_padding_bottom = excluded.reader_padding_bottom,
          reader_padding_left = excluded.reader_padding_left,
          reader_padding_right = excluded.reader_padding_right,
          reader_landscape_double_page = excluded.reader_landscape_double_page,
          reader_single_page_position = excluded.reader_single_page_position,
          reader_avoid_notch = excluded.reader_avoid_notch,
          reader_show_preface = excluded.reader_show_preface,
          reader_show_afterword = excluded.reader_show_afterword
        ''',
        <Object?>[
          1,
          settings.themeMode.storageValue,
          settings.openHomeNovelDirectlyInReader ? 1 : 0,
          settings.reader.writingMode.storageValue,
          settings.reader.tapPattern.storageValue,
          settings.reader.usePaperTexture ? 1 : 0,
          settings.reader.paperColorPreset.storageValue,
          settings.reader.fontSize,
          settings.reader.paddingTop,
          settings.reader.paddingBottom,
          settings.reader.paddingLeft,
          settings.reader.paddingRight,
          settings.reader.enableLandscapeDoublePage ? 1 : 0,
          settings.reader.singlePagePosition.storageValue,
          settings.reader.avoidNotch ? 1 : 0,
          settings.reader.showPreface ? 1 : 0,
          settings.reader.showAfterword ? 1 : 0,
        ],
      );
    });
    _changesController.add(null);
  }

  Future<void> dispose() async {
    await _changesController.close();
  }

  AppSettings _appSettingsFromRow(sqlite.Row row) {
    return AppSettings(
      themeMode: AppThemeModeX.fromStorageValue(row['theme_mode'] as String?),
      openHomeNovelDirectlyInReader:
          _intValue(row['open_home_novel_directly_in_reader']) != 0,
      reader: ReaderSettings(
        writingMode: ReaderWritingModeX.fromStorageValue(
          row['reader_writing_mode'] as String?,
        ),
        tapPattern: ReaderTapPatternX.fromStorageValue(
          row['reader_tap_pattern'] as String?,
        ),
        usePaperTexture: _intValue(row['reader_use_paper_texture']) != 0,
        paperColorPreset: ReaderPaperColorPresetX.fromStorageValue(
          row['reader_paper_color'] as String?,
        ),
        fontSize: _doubleValue(row['reader_font_size']),
        paddingTop: _doubleValue(row['reader_padding_top']),
        paddingBottom: _doubleValue(row['reader_padding_bottom']),
        paddingLeft: _doubleValue(row['reader_padding_left']),
        paddingRight: _doubleValue(row['reader_padding_right']),
        enableLandscapeDoublePage:
            _intValue(row['reader_landscape_double_page']) != 0,
        singlePagePosition: ReaderSinglePagePositionX.fromStorageValue(
          row['reader_single_page_position'] as String?,
        ),
        avoidNotch: _intValue(row['reader_avoid_notch']) != 0,
        showPreface: _intValue(row['reader_show_preface']) != 0,
        showAfterword: _intValue(row['reader_show_afterword']) != 0,
      ),
    );
  }

  int _intValue(Object? value) {
    return switch (value) {
      int() => value,
      num() => value.toInt(),
      _ => 0,
    };
  }

  double _doubleValue(Object? value) {
    return switch (value) {
      double() => value,
      int() => value.toDouble(),
      _ => 0,
    };
  }
}
