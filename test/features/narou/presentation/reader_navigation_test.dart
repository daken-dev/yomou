import 'package:flutter_test/flutter_test.dart';
import 'package:kumihan/kumihan.dart';
import 'package:yomou/features/narou/presentation/reader_navigation.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

void main() {
  group('resolveReaderTapAction', () {
    test('maps horizontal thirds for left-center-right', () {
      expect(
        resolveReaderTapAction(
          pattern: ReaderTapPattern.leftCenterRight,
          normalizedX: 0.2,
          normalizedY: 0.9,
        ),
        ReaderTapAction.backward,
      );
      expect(
        resolveReaderTapAction(
          pattern: ReaderTapPattern.leftCenterRight,
          normalizedX: 0.5,
          normalizedY: 0.1,
        ),
        ReaderTapAction.toggleControls,
      );
      expect(
        resolveReaderTapAction(
          pattern: ReaderTapPattern.leftCenterRight,
          normalizedX: 0.9,
          normalizedY: 0.1,
        ),
        ReaderTapAction.forward,
      );
    });

    test('maps vertical thirds for top-center-bottom', () {
      expect(
        resolveReaderTapAction(
          pattern: ReaderTapPattern.topCenterBottom,
          normalizedX: 0.9,
          normalizedY: 0.2,
        ),
        ReaderTapAction.backward,
      );
      expect(
        resolveReaderTapAction(
          pattern: ReaderTapPattern.topCenterBottom,
          normalizedX: 0.1,
          normalizedY: 0.5,
        ),
        ReaderTapAction.toggleControls,
      );
      expect(
        resolveReaderTapAction(
          pattern: ReaderTapPattern.topCenterBottom,
          normalizedX: 0.1,
          normalizedY: 0.9,
        ),
        ReaderTapAction.forward,
      );
    });
  });

  group('tapSideForDirection', () {
    test('uses left tap as forward in vertical mode', () {
      const snapshot = KumihanSnapshot(
        currentPage: 0,
        spreadMode: KumihanSpreadMode.single,
        totalPages: 10,
        writingMode: KumihanWritingMode.vertical,
      );

      expect(
        tapSideForDirection(snapshot: snapshot, isForward: true),
        KumihanTapSide.left,
      );
      expect(
        tapSideForDirection(snapshot: snapshot, isForward: false),
        KumihanTapSide.right,
      );
    });

    test('uses right tap as forward in horizontal mode', () {
      const snapshot = KumihanSnapshot(
        currentPage: 0,
        spreadMode: KumihanSpreadMode.single,
        totalPages: 10,
        writingMode: KumihanWritingMode.horizontal,
      );

      expect(
        tapSideForDirection(snapshot: snapshot, isForward: true),
        KumihanTapSide.right,
      );
      expect(
        tapSideForDirection(snapshot: snapshot, isForward: false),
        KumihanTapSide.left,
      );
    });
  });

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
