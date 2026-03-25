import 'package:kumihan/kumihan.dart';

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
