import 'package:yomou/features/settings/domain/entities/app_settings.dart';

enum ReaderTapAction { backward, toggleControls, forward }

ReaderTapAction resolveReaderTapAction({
  required ReaderTapPattern pattern,
  required double normalizedX,
  required double normalizedY,
}) {
  return switch (pattern) {
    ReaderTapPattern.leftCenterRight => _resolveTapActionFromAxis(
      1 - normalizedX,
    ),
    ReaderTapPattern.topCenterBottom => _resolveTapActionFromAxis(normalizedY),
  };
}

bool isAtReaderTurnEdge({
  required int currentPage,
  required int totalPages,
  required int pageTurnAmount,
  required bool isForward,
}) {
  if (totalPages <= 0) {
    return true;
  }
  if (!isForward) {
    return currentPage < pageTurnAmount;
  }
  final lastTurnStart = (totalPages - pageTurnAmount).clamp(0, 1 << 30);
  return currentPage >= lastTurnStart;
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
