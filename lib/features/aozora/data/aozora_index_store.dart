import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:yomou/core/database/app_database.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';

class AozoraIndexStore {
  AozoraIndexStore(this._database);

  final AppDatabase _database;

  Future<AozoraIndexStatus> getStatus() async {
    return _database.read((db) {
      final countRows = db.select('SELECT COUNT(*) AS count FROM aozora_works');
      final count = _intValue(countRows.first['count']);
      final metaRows = db.select(
        'SELECT fetched_at FROM aozora_index_meta WHERE id = 1 LIMIT 1',
      );
      final fetchedAtText = metaRows.isEmpty
          ? null
          : metaRows.first['fetched_at'] as String?;
      return AozoraIndexStatus(
        totalWorks: count,
        fetchedAt: fetchedAtText == null ? null : DateTime.parse(fetchedAtText),
      );
    });
  }

  Future<void> replaceAll({
    required List<AozoraWorkRecord> works,
    required DateTime fetchedAt,
    required String sourceUrl,
  }) async {
    await _database.write((db) {
      db.execute('DELETE FROM aozora_works');

      final now = fetchedAt.toIso8601String();
      for (final work in works) {
        db.execute(
          '''
          INSERT INTO aozora_works (
            work_id,
            title,
            title_reading,
            subtitle,
            subtitle_reading,
            original_title,
            first_appearance,
            classification,
            writing_style,
            work_copyright,
            publication_date,
            csv_updated_date,
            author_name,
            role,
            birth_date,
            death_date,
            person_copyright,
            card_url,
            text_zip_url,
            text_encoding,
            html_url,
            html_encoding,
            inputter,
            proofreader,
            updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            work.id,
            work.title,
            work.titleReading,
            work.subtitle,
            work.subtitleReading,
            work.originalTitle,
            work.firstAppearance,
            work.classification,
            work.writingStyle,
            work.workCopyright,
            work.publicationDate,
            work.csvUpdatedDate,
            work.author,
            work.role,
            work.birthDate,
            work.deathDate,
            work.personCopyright,
            work.cardUrl,
            work.textZipUrl,
            work.textEncoding,
            work.htmlUrl,
            work.htmlEncoding,
            work.inputter,
            work.proofreader,
            now,
          ],
        );
      }

      db.execute(
        '''
        INSERT INTO aozora_index_meta (
          id,
          fetched_at,
          source_url,
          total_works
        ) VALUES (1, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          fetched_at = excluded.fetched_at,
          source_url = excluded.source_url,
          total_works = excluded.total_works
        ''',
        <Object?>[now, sourceUrl, works.length],
      );
    });
  }

  Future<AozoraWorkRecord?> findByWorkId(String workId) async {
    return _database.read((db) {
      final rows = db.select(
        '''
        SELECT
          work_id,
          title,
          title_reading,
          subtitle,
          subtitle_reading,
          original_title,
          first_appearance,
          classification,
          writing_style,
          work_copyright,
          publication_date,
          csv_updated_date,
          author_name,
          role,
          birth_date,
          death_date,
          person_copyright,
          card_url,
          text_zip_url,
          text_encoding,
          html_url,
          html_encoding,
          inputter,
          proofreader,
          updated_at
        FROM aozora_works
        WHERE work_id = ?
        LIMIT 1
        ''',
        <Object?>[workId],
      );
      if (rows.isEmpty) {
        return null;
      }
      return _workFromRow(rows.first);
    });
  }

  Future<PagedAozoraWorks> searchWorks({
    required String query,
    required NovelSearchTarget target,
    required int page,
    required int pageSize,
  }) async {
    final normalizedQuery = query.trim();
    final safePage = page < 1 ? 1 : page;
    final safePageSize = pageSize < 1 ? 20 : pageSize;
    final offset = (safePage - 1) * safePageSize;

    return _database.read((db) {
      if (normalizedQuery.isEmpty) {
        final totalRows = db.select(
          'SELECT COUNT(*) AS count FROM aozora_works',
        );
        final totalCount = _intValue(totalRows.first['count']);
        final rows = db.select(
          '''
          SELECT
            work_id,
            title,
            title_reading,
            subtitle,
            subtitle_reading,
            original_title,
            first_appearance,
            classification,
            writing_style,
            work_copyright,
            publication_date,
            csv_updated_date,
            author_name,
            role,
            birth_date,
            death_date,
            person_copyright,
            card_url,
            text_zip_url,
            text_encoding,
            html_url,
            html_encoding,
            inputter,
            proofreader,
            updated_at
          FROM aozora_works
          ORDER BY title_reading COLLATE NOCASE, title COLLATE NOCASE, work_id
          LIMIT ? OFFSET ?
          ''',
          <Object?>[safePageSize, offset],
        );
        return PagedAozoraWorks(
          items: rows.map(_workFromRow).toList(growable: false),
          totalCount: totalCount,
          page: safePage,
          pageSize: safePageSize,
        );
      }

      final escaped = _escapeLike(normalizedQuery);
      final pattern = '%$escaped%';
      final whereClause = _whereClauseForTarget(target);
      final likeParams = _likeParamsForTarget(target, pattern);
      final params = <Object?>[...likeParams, safePageSize, offset];

      final totalRows = db.select(
        'SELECT COUNT(*) AS count FROM aozora_works WHERE $whereClause',
        likeParams,
      );
      final totalCount = _intValue(totalRows.first['count']);
      final rows = db.select('''
        SELECT
          work_id,
          title,
          title_reading,
          subtitle,
          subtitle_reading,
          original_title,
          first_appearance,
          classification,
          writing_style,
          work_copyright,
          publication_date,
          csv_updated_date,
          author_name,
          role,
          birth_date,
          death_date,
          person_copyright,
          card_url,
          text_zip_url,
          text_encoding,
          html_url,
          html_encoding,
          inputter,
          proofreader,
          updated_at
        FROM aozora_works
        WHERE $whereClause
        ORDER BY title_reading COLLATE NOCASE, title COLLATE NOCASE, work_id
        LIMIT ? OFFSET ?
        ''', params);

      return PagedAozoraWorks(
        items: rows.map(_workFromRow).toList(growable: false),
        totalCount: totalCount,
        page: safePage,
        pageSize: safePageSize,
      );
    });
  }

  String _whereClauseForTarget(NovelSearchTarget target) {
    return switch (target) {
      NovelSearchTarget.title =>
        "(title LIKE ? ESCAPE '\\' OR IFNULL(subtitle, '') LIKE ? ESCAPE '\\')",
      NovelSearchTarget.author => "author_name LIKE ? ESCAPE '\\'",
      NovelSearchTarget.story => "(title LIKE ? ESCAPE '\\')",
      NovelSearchTarget.keyword => "(title LIKE ? ESCAPE '\\')",
      NovelSearchTarget.all =>
        "(title LIKE ? ESCAPE '\\' OR IFNULL(subtitle, '') LIKE ? ESCAPE '\\' OR author_name LIKE ? ESCAPE '\\')",
    };
  }

  List<Object?> _likeParamsForTarget(NovelSearchTarget target, String pattern) {
    return switch (target) {
      NovelSearchTarget.title => <Object?>[pattern, pattern],
      NovelSearchTarget.author => <Object?>[pattern],
      NovelSearchTarget.story => <Object?>[pattern],
      NovelSearchTarget.keyword => <Object?>[pattern],
      NovelSearchTarget.all => <Object?>[pattern, pattern, pattern],
    };
  }

  String _escapeLike(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }

  AozoraWorkRecord _workFromRow(sqlite.Row row) {
    return AozoraWorkRecord(
      id: row['work_id']! as String,
      title: row['title']! as String,
      titleReading: row['title_reading'] as String?,
      subtitle: row['subtitle'] as String?,
      subtitleReading: row['subtitle_reading'] as String?,
      originalTitle: row['original_title'] as String?,
      firstAppearance: row['first_appearance'] as String?,
      classification: row['classification'] as String?,
      writingStyle: row['writing_style'] as String?,
      workCopyright: row['work_copyright'] as String?,
      publicationDate: row['publication_date'] as String?,
      csvUpdatedDate: row['csv_updated_date'] as String?,
      author: row['author_name']! as String,
      role: row['role'] as String?,
      birthDate: row['birth_date'] as String?,
      deathDate: row['death_date'] as String?,
      personCopyright: row['person_copyright'] as String?,
      cardUrl: row['card_url'] as String?,
      textZipUrl: row['text_zip_url']! as String,
      textEncoding: row['text_encoding'] as String?,
      htmlUrl: row['html_url'] as String?,
      htmlEncoding: row['html_encoding'] as String?,
      inputter: row['inputter'] as String?,
      proofreader: row['proofreader'] as String?,
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  int _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value == null) {
      return 0;
    }
    return int.parse(value.toString());
  }
}

class AozoraWorkRecord {
  const AozoraWorkRecord({
    required this.id,
    required this.title,
    required this.author,
    required this.textZipUrl,
    required this.updatedAt,
    this.titleReading,
    this.subtitle,
    this.subtitleReading,
    this.originalTitle,
    this.firstAppearance,
    this.classification,
    this.writingStyle,
    this.workCopyright,
    this.publicationDate,
    this.csvUpdatedDate,
    this.role,
    this.birthDate,
    this.deathDate,
    this.personCopyright,
    this.cardUrl,
    this.textEncoding,
    this.htmlUrl,
    this.htmlEncoding,
    this.inputter,
    this.proofreader,
  });

  final String id;
  final String title;
  final String? titleReading;
  final String? subtitle;
  final String? subtitleReading;
  final String? originalTitle;
  final String? firstAppearance;
  final String? classification;
  final String? writingStyle;
  final String? workCopyright;
  final String? publicationDate;
  final String? csvUpdatedDate;
  final String author;
  final String? role;
  final String? birthDate;
  final String? deathDate;
  final String? personCopyright;
  final String? cardUrl;
  final String textZipUrl;
  final String? textEncoding;
  final String? htmlUrl;
  final String? htmlEncoding;
  final String? inputter;
  final String? proofreader;
  final DateTime updatedAt;
}

class AozoraIndexStatus {
  const AozoraIndexStatus({required this.totalWorks, required this.fetchedAt});

  final int totalWorks;
  final DateTime? fetchedAt;

  bool get hasIndex => totalWorks > 0 && fetchedAt != null;
}

class PagedAozoraWorks {
  const PagedAozoraWorks({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<AozoraWorkRecord> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < totalCount;
  int get nextPage => hasMore ? page + 1 : page;
}
