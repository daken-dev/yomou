import 'package:flutter_test/flutter_test.dart';
import 'package:kumihan/kumihan.dart';
import 'package:yomou/features/narou/presentation/reader_navigation.dart';

void main() {
  group('isAtReaderTurnEdge', () {
    test('treats the last single page as forward edge', () {
      const snapshot = KumihanSnapshot(
        currentPage: 9,
        spreadMode: KumihanSpreadMode.single,
        totalPages: 10,
        writingMode: KumihanWritingMode.vertical,
      );

      expect(isAtReaderTurnEdge(snapshot: snapshot, isForward: true), isTrue);
    });

    test('treats the last double-page spread as forward edge', () {
      const snapshot = KumihanSnapshot(
        currentPage: 8,
        spreadMode: KumihanSpreadMode.doublePage,
        totalPages: 10,
        writingMode: KumihanWritingMode.vertical,
      );

      expect(isAtReaderTurnEdge(snapshot: snapshot, isForward: true), isTrue);
    });

    test(
      'does not treat the penultimate double-page spread as forward edge',
      () {
        const snapshot = KumihanSnapshot(
          currentPage: 6,
          spreadMode: KumihanSpreadMode.doublePage,
          totalPages: 10,
          writingMode: KumihanWritingMode.vertical,
        );

        expect(
          isAtReaderTurnEdge(snapshot: snapshot, isForward: true),
          isFalse,
        );
      },
    );

    test('treats the first page as backward edge', () {
      const snapshot = KumihanSnapshot(
        currentPage: 0,
        spreadMode: KumihanSpreadMode.doublePage,
        totalPages: 10,
        writingMode: KumihanWritingMode.vertical,
      );

      expect(isAtReaderTurnEdge(snapshot: snapshot, isForward: false), isTrue);
    });
  });
}
