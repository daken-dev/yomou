import 'package:kumihan/kumihan.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

enum ReaderTapAction { backward, toggleControls, forward }

ReaderTapAction resolveReaderTapAction({
  required ReaderTapPattern pattern,
  required double normalizedX,
  required double normalizedY,
}) {
  return switch (pattern) {
    // 縦書き：左が進む・右が戻る
    ReaderTapPattern.leftCenterRight => _resolveTapActionFromAxis(1 - normalizedX),
    ReaderTapPattern.topCenterBottom => _resolveTapActionFromAxis(normalizedY),
  };
}

KumihanTapSide tapSideForDirection({
  required KumihanSnapshot snapshot,
  required bool isForward,
}) {
  return switch (snapshot.writingMode) {
    KumihanWritingMode.vertical =>
      isForward ? KumihanTapSide.left : KumihanTapSide.right,
    KumihanWritingMode.horizontal =>
      isForward ? KumihanTapSide.right : KumihanTapSide.left,
  };
}

bool isAtReaderTurnEdge({
  required KumihanSnapshot snapshot,
  required bool isForward,
}) {
  if (snapshot.totalPages <= 0) {
    return true;
  }

  if (!isForward) {
    return snapshot.currentPage <= 0;
  }

  final turnAmount = switch (snapshot.spreadMode) {
    KumihanSpreadMode.single => 1,
    KumihanSpreadMode.doublePage => 2,
  };
  final lastTurnStart = (snapshot.totalPages - turnAmount).clamp(0, 1 << 30);
  return snapshot.currentPage >= lastTurnStart;
}

ReaderTapAction _resolveTapActionFromAxis(double value) {
  if (value <= 1 / 3) {
    return ReaderTapAction.backward;
  }
  if (value >= 2 / 3) {
    return ReaderTapAction.forward;
  }
  return ReaderTapAction.toggleControls;
}
