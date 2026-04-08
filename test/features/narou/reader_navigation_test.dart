import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/features/narou/presentation/reader_navigation.dart';

void main() {
  group('isAtReaderTurnEdge', () {
    test('treats the last single page as forward edge', () {
      expect(
        isAtReaderTurnEdge(
          currentPage: 9,
          totalPages: 10,
          pageTurnAmount: 1,
          isForward: true,
        ),
        isTrue,
      );
    });

    test('treats the last double-page spread as forward edge', () {
      expect(
        isAtReaderTurnEdge(
          currentPage: 8,
          totalPages: 10,
          pageTurnAmount: 2,
          isForward: true,
        ),
        isTrue,
      );
    });

    test(
      'does not treat the penultimate double-page spread as forward edge',
      () {
        expect(
          isAtReaderTurnEdge(
            currentPage: 6,
            totalPages: 10,
            pageTurnAmount: 2,
            isForward: true,
          ),
          isFalse,
        );
      },
    );

    test('treats the first page as backward edge', () {
      expect(
        isAtReaderTurnEdge(
          currentPage: 0,
          totalPages: 10,
          pageTurnAmount: 2,
          isForward: false,
        ),
        isTrue,
      );
    });

    test('treats the first double-page spread as backward edge', () {
      expect(
        isAtReaderTurnEdge(
          currentPage: 1,
          totalPages: 10,
          pageTurnAmount: 2,
          isForward: false,
        ),
        isTrue,
      );
    });

    test('does not treat the second double-page spread as backward edge', () {
      expect(
        isAtReaderTurnEdge(
          currentPage: 2,
          totalPages: 10,
          pageTurnAmount: 2,
          isForward: false,
        ),
        isFalse,
      );
    });
  });
}
