import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

typedef DatabasePathProvider = Future<String> Function();

Future<String> defaultDatabasePathProvider() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return path.join(directory.path, 'yomou.sqlite');
}

class AppDatabase {
  AppDatabase({DatabasePathProvider? pathProvider})
    : _pathProvider = pathProvider ?? defaultDatabasePathProvider;

  final DatabasePathProvider _pathProvider;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  sqlite.Database? _database;
  Future<sqlite.Database>? _opening;

  Stream<void> get changes => _changesController.stream;

  Future<T> read<T>(T Function(sqlite.Database db) action) async {
    final database = await _open();
    return action(database);
  }

  Future<T> write<T>(
    T Function(sqlite.Database db) action, {
    bool notify = true,
  }) async {
    final database = await _open();

    database.execute('BEGIN IMMEDIATE');
    try {
      final result = action(database);
      database.execute('COMMIT');
      if (notify) {
        _changesController.add(null);
      }
      return result;
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> dispose() async {
    final opening = _opening;
    if (opening != null) {
      await opening;
    }
    _database?.dispose();
    await _changesController.close();
  }

  Future<sqlite.Database> _open() {
    final existing = _database;
    if (existing != null) {
      return Future<sqlite.Database>.value(existing);
    }

    final opening = _opening;
    if (opening != null) {
      return opening;
    }

    return _opening = _openInternal();
  }

  Future<sqlite.Database> _openInternal() async {
    final databasePath = await _pathProvider();
    final parent = Directory(path.dirname(databasePath));
    await parent.create(recursive: true);

    final database = sqlite.sqlite3.open(databasePath);
    _initialize(database);
    _database = database;
    return database;
  }

  void _initialize(sqlite.Database database) {
    database.execute('PRAGMA foreign_keys = ON');
    database.execute('PRAGMA journal_mode = WAL');
    final currentVersion =
        database.select('PRAGMA user_version').first.columnAt(0) as int;

    if (currentVersion == 0) {
      _createSchema(database);
      database.execute('PRAGMA user_version = 2');
      return;
    }

    if (currentVersion < 2) {
      _migrateToV2(database);
      database.execute('PRAGMA user_version = 2');
    }
  }

  void _createSchema(sqlite.Database database) {
    database.execute('''
      CREATE TABLE IF NOT EXISTS saved_novels (
        site TEXT NOT NULL,
        novel_id TEXT NOT NULL,
        title TEXT NOT NULL,
        author_name TEXT,
        author_url TEXT,
        summary TEXT,
        summary_html TEXT,
        info_url TEXT,
        toc_url TEXT,
        info_payload_json TEXT,
        toc_payload_json TEXT,
        latest_episode_published TEXT,
        total_episodes INTEGER NOT NULL DEFAULT 0,
        toc_page_count INTEGER NOT NULL DEFAULT 0,
        update_locked INTEGER NOT NULL DEFAULT 0,
        lock_reason TEXT,
        last_error TEXT,
        last_checked_at TEXT,
        last_synced_at TEXT,
        next_refresh_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (site, novel_id)
      )
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS novel_episodes (
        site TEXT NOT NULL,
        novel_id TEXT NOT NULL,
        episode_no INTEGER NOT NULL,
        title TEXT NOT NULL,
        episode_url TEXT NOT NULL,
        chapter_title TEXT,
        index_page INTEGER,
        published_at TEXT,
        revised_at TEXT,
        preface TEXT,
        preface_html TEXT,
        body TEXT,
        body_html TEXT,
        afterword TEXT,
        afterword_html TEXT,
        page_payload_json TEXT,
        is_downloaded INTEGER NOT NULL DEFAULT 0,
        last_downloaded_at TEXT,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (site, novel_id, episode_no),
        FOREIGN KEY (site, novel_id)
          REFERENCES saved_novels(site, novel_id)
          ON DELETE CASCADE
      )
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS novel_episodes_lookup_idx
      ON novel_episodes(site, novel_id, is_downloaded, episode_no)
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS download_jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        site TEXT NOT NULL,
        novel_id TEXT NOT NULL,
        job_type TEXT NOT NULL,
        episode_no INTEGER,
        force INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        run_after TEXT NOT NULL,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        FOREIGN KEY (site, novel_id)
          REFERENCES saved_novels(site, novel_id)
          ON DELETE CASCADE
      )
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS download_jobs_pick_idx
      ON download_jobs(status, run_after, priority DESC, created_at)
    ''');

    database.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS download_jobs_active_unique
      ON download_jobs(site, novel_id, job_type, IFNULL(episode_no, -1))
      WHERE status IN ('queued', 'running')
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS novel_bookmarks (
        site TEXT NOT NULL,
        novel_id TEXT NOT NULL,
        episode_no INTEGER NOT NULL DEFAULT 1,
        scroll_offset REAL NOT NULL DEFAULT 0,
        page_number INTEGER NOT NULL DEFAULT 1,
        page_count INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (site, novel_id),
        FOREIGN KEY (site, novel_id)
          REFERENCES saved_novels(site, novel_id)
          ON DELETE CASCADE
      )
    ''');
  }

  void _migrateToV2(sqlite.Database database) {
    database.execute('''
      ALTER TABLE novel_bookmarks
      ADD COLUMN page_number INTEGER NOT NULL DEFAULT 1
    ''');
    database.execute('''
      ALTER TABLE novel_bookmarks
      ADD COLUMN page_count INTEGER NOT NULL DEFAULT 0
    ''');
  }
}
