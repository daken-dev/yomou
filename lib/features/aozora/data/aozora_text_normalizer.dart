class AozoraTextNormalizer {
  const AozoraTextNormalizer._();

  // 青空文庫テキスト冒頭の「テキスト中に現れる記号について」を除去する。
  static String stripIntroBlock(String rawText) {
    final normalized = rawText.replaceAll(RegExp(r'(\r\n|\r)'), '\n').trim();
    if (normalized.isEmpty) {
      return normalized;
    }

    final start = normalized.indexOf('-------------------------------------------------------');
    if (start < 0) {
      return normalized;
    }

    final end = normalized.indexOf('-------------------------------------------------------', start + 1);
    if (end < 0) {
      return normalized;
    }

    final before = normalized.substring(0, start);
    final after = normalized.substring(end + '-------------------------------------------------------'.length).trimLeft();
    final result = (before + after).trim();
    if (result.isEmpty) {
      return normalized;
    }
    return result;
  }
}
