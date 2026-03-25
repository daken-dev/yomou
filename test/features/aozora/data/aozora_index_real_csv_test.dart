import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/features/aozora/data/aozora_index_client.dart';

void main() {
  test('parse real CSV file', () {
    final file = File('list_person_all_extended_utf8.csv');
    if (!file.existsSync()) {
      markTestSkipped('CSV file not available');
      return;
    }

    final csvText = file
        .readAsStringSync()
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvText);

    // ignore: avoid_print
    print('Number of rows: ${rows.length}');
    if (rows.isNotEmpty) {
      // ignore: avoid_print
      print('Header columns: ${rows.first.length}');
    }
    if (rows.length > 1) {
      // ignore: avoid_print
      print('Row 1 columns: ${rows[1].length}');
    }

    expect(rows.length, greaterThan(1000));

    final client = AozoraIndexClient(Dio());
    final works = client.parseRowsForTest(rows);
    // ignore: avoid_print
    print('Number of works: ${works.length}');
    expect(works.length, greaterThan(1000));
  });
}
