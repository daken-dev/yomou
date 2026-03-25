import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jis0208/jis0208.dart';
import 'package:yomou/features/aozora/data/aozora_index_store.dart';

const String aozoraIndexZipUrl =
    'https://www.aozora.gr.jp/index_pages/list_person_all_extended_utf8.zip';

class AozoraIndexClient {
  AozoraIndexClient(this._dio);

  final Dio _dio;

  Future<List<AozoraWorkRecord>> fetchIndex() async {
    final response = await _dio.get<List<int>>(
      aozoraIndexZipUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: const <String, Object>{'Accept': 'application/zip,*/*'},
      ),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('青空文庫インデックスのダウンロードに失敗しました。');
    }

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final csvFile = archive.files.firstWhere(
      (file) => !file.isFile ? false : file.name.toLowerCase().endsWith('.csv'),
      orElse: () => throw const FormatException('CSVファイルが見つかりません。'),
    );

    final csvText = _decodeText(csvFile.content as List<int>)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvText);

    if (rows.length <= 1) {
      return const <AozoraWorkRecord>[];
    }

    return parseRowsForTest(rows);
  }

  String _decodeText(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return Windows31JCodec().decode(bytes);
    }
  }

  @visibleForTesting
  List<AozoraWorkRecord> parseRowsForTest(List<List<dynamic>> rows) {
    final header = rows.first
        .map((value) => '$value'.replaceAll('\uFEFF', '').trim())
        .toList(growable: false);

    final workIdIndex = _findHeaderIndex(header, const ['作品ID']);
    final titleIndex = _findHeaderIndex(header, const ['作品名']);
    final titleReadingIndex = _findHeaderIndex(header, const ['作品名読み']);
    final subtitleIndex = _findHeaderIndex(header, const ['副題']);
    final subtitleReadingIndex = _findHeaderIndex(header, const ['副題読み']);
    final originalTitleIndex = _findHeaderIndex(header, const ['原題']);
    final firstAppearanceIndex = _findHeaderIndex(header, const ['初出']);
    final classificationIndex = _findHeaderIndex(header, const ['分類番号']);
    final writingStyleIndex = _findHeaderIndex(header, const ['文字遣い種別']);
    final workCopyrightIndex = _findHeaderIndex(header, const ['作品著作権フラグ']);
    final publicationDateIndex = _findHeaderIndex(header, const ['公開日']);
    final csvUpdatedDateIndex = _findHeaderIndex(header, const ['最終更新日']);
    final authorNameIndex = _findHeaderIndex(header, const ['著者名']);
    final lastNameIndex = _findHeaderIndex(header, const ['姓']);
    final firstNameIndex = _findHeaderIndex(header, const ['名']);
    final cardUrlIndex = _findHeaderIndex(header, const ['図書カードURL']);
    final textUrlIndex = _findHeaderIndex(header, const ['テキストファイルURL']);
    final textEncodingIndex = _findHeaderIndex(header, const ['テキストファイル符号化方式']);
    final htmlUrlIndex = _findHeaderIndex(header, const ['XHTML/HTMLファイルURL']);
    final htmlEncodingIndex = _findHeaderIndex(header, const [
      'XHTML/HTMLファイル符号化方式',
    ]);
    final inputterIndex = _findHeaderIndex(header, const ['入力者']);
    final proofreaderIndex = _findHeaderIndex(header, const ['校正者']);
    final roleIndex = _findHeaderIndex(header, const ['役割フラグ']);
    final birthDateIndex = _findHeaderIndex(header, const ['生年月日']);
    final deathDateIndex = _findHeaderIndex(header, const ['没年月日']);
    final personCopyrightIndex = _findHeaderIndex(header, const ['人物著作権フラグ']);

    final worksById = <String, AozoraWorkRecord>{};
    for (var index = 1; index < rows.length; index += 1) {
      final row = rows[index];
      final explicitWorkId = _normalizeWorkId(_stringAt(row, workIdIndex));
      final title = _stringAt(row, titleIndex) ?? _fallbackTitle(row);
      final textZipUrl =
          _normalizeUrl(_stringAt(row, textUrlIndex)) ??
          _normalizeUrl(_extractTextZipUrl(row));
      final cardUrl =
          _normalizeUrl(_stringAt(row, cardUrlIndex)) ??
          _normalizeUrl(_extractCardUrl(row));
      final workId =
          explicitWorkId ??
          _extractWorkId(row) ??
          _extractWorkIdFromCardUrl(cardUrl) ??
          _extractWorkIdFromTextZipUrl(textZipUrl);

      if (title == null || textZipUrl == null) {
        continue;
      }
      if (!textZipUrl.toLowerCase().endsWith('.zip')) {
        continue;
      }

      final role = _stringAt(row, roleIndex);
      final authorName = _resolveAuthor(
        explicitAuthor: _stringAt(row, authorNameIndex),
        lastName: _stringAt(row, lastNameIndex),
        firstName: _stringAt(row, firstNameIndex),
      );
      final next = AozoraWorkRecord(
        id: workId ?? textZipUrl,
        title: title,
        titleReading: _stringAt(row, titleReadingIndex),
        subtitle: _stringAt(row, subtitleIndex),
        subtitleReading: _stringAt(row, subtitleReadingIndex),
        originalTitle: _stringAt(row, originalTitleIndex),
        firstAppearance: _stringAt(row, firstAppearanceIndex),
        classification: _stringAt(row, classificationIndex),
        writingStyle: _stringAt(row, writingStyleIndex),
        workCopyright: _stringAt(row, workCopyrightIndex),
        publicationDate: _stringAt(row, publicationDateIndex),
        csvUpdatedDate: _stringAt(row, csvUpdatedDateIndex),
        author: authorName ?? '不明',
        role: role,
        birthDate: _stringAt(row, birthDateIndex),
        deathDate: _stringAt(row, deathDateIndex),
        personCopyright: _stringAt(row, personCopyrightIndex),
        cardUrl: cardUrl,
        textZipUrl: textZipUrl,
        textEncoding: _stringAt(row, textEncodingIndex),
        htmlUrl: _normalizeUrl(_stringAt(row, htmlUrlIndex)),
        htmlEncoding: _stringAt(row, htmlEncodingIndex),
        inputter: _stringAt(row, inputterIndex),
        proofreader: _stringAt(row, proofreaderIndex),
        updatedAt: DateTime.now(),
      );

      final dedupeKey = workId ?? 'zip:$textZipUrl';
      final existing = worksById[dedupeKey];
      if (existing == null) {
        worksById[dedupeKey] = next;
        continue;
      }
      if ((role ?? '').contains('著者')) {
        worksById[dedupeKey] = next;
      }
    }

    final works = worksById.values.toList(growable: false);
    works.sort((left, right) {
      final byTitle = left.title.compareTo(right.title);
      if (byTitle != 0) {
        return byTitle;
      }
      return left.id.compareTo(right.id);
    });
    return works;
  }

  int? _findHeaderIndex(List<String> header, List<String> candidates) {
    for (var i = 0; i < header.length; i += 1) {
      final value = header[i];
      for (final candidate in candidates) {
        if (value == candidate) {
          return i;
        }
      }
    }

    for (var i = 0; i < header.length; i += 1) {
      final value = header[i];
      for (final candidate in candidates) {
        if (value.contains(candidate)) {
          return i;
        }
      }
    }
    return null;
  }

  String? _normalizeWorkId(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final match = RegExp(r'\d+').firstMatch(value);
    return match?.group(0);
  }

  String? _stringAt(List<dynamic> row, int? index) {
    if (index == null || index < 0 || index >= row.length) {
      return null;
    }
    final value = '${row[index]}'.trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  String? _resolveAuthor({
    required String? explicitAuthor,
    required String? lastName,
    required String? firstName,
  }) {
    if (explicitAuthor != null && explicitAuthor.isNotEmpty) {
      return explicitAuthor;
    }
    final name = '${lastName ?? ''}${firstName ?? ''}'.trim();
    if (name.isEmpty) {
      return null;
    }
    return name;
  }

  String? _normalizeUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return null;
    }
    if (uri.hasScheme) {
      return uri.toString();
    }
    return Uri.parse('https://www.aozora.gr.jp/').resolveUri(uri).toString();
  }

  String? _extractWorkId(List<dynamic> row) {
    for (final cell in row) {
      final text = '$cell';
      final match = RegExp(r'card(\d+)\.html').firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  String? _extractWorkIdFromCardUrl(String? url) {
    if (url == null) {
      return null;
    }
    return RegExp(r'card(\d+)\.html').firstMatch(url)?.group(1);
  }

  String? _extractWorkIdFromTextZipUrl(String? url) {
    if (url == null) {
      return null;
    }
    return RegExp(r'/files/(\d+)_').firstMatch(url)?.group(1);
  }

  String? _fallbackTitle(List<dynamic> row) {
    for (final cell in row) {
      final text = '$cell'.trim();
      if (text.isEmpty) {
        continue;
      }
      if (text.contains('http://') || text.contains('https://')) {
        continue;
      }
      return text;
    }
    return null;
  }

  String? _extractTextZipUrl(List<dynamic> row) {
    for (final cell in row) {
      final text = '$cell'.trim();
      final absoluteMatch = RegExp(
        "https?://[^\\s\"'<>]*?/files/[^\\s\"'<>]*?\\.zip",
        caseSensitive: false,
      ).firstMatch(text);
      if (absoluteMatch != null) {
        return absoluteMatch.group(0);
      }
      final relativeMatch = RegExp(
        "/[^\\s\"'<>]*?/files/[^\\s\"'<>]*?\\.zip",
        caseSensitive: false,
      ).firstMatch(text);
      if (relativeMatch != null) {
        return relativeMatch.group(0);
      }
    }
    return null;
  }

  String? _extractCardUrl(List<dynamic> row) {
    for (final cell in row) {
      final text = '$cell'.trim();
      if (!text.contains('/cards/') ||
          !text.contains('card') ||
          !text.contains('.html')) {
        continue;
      }
      return text;
    }
    return null;
  }
}
