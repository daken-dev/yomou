import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/features/aozora/data/aozora_text_normalizer.dart';

void main() {
  group('AozoraTextNormalizer.stripIntroBlock', () {
    test('removes dashed intro block at top', () {
      const raw = '''眞間名所
阪井久良伎

-------------------------------------------------------
【テキスト中に現れる記号について】

《》：ルビ
-------------------------------------------------------

本文1行目
本文2行目
''';

      final normalized = AozoraTextNormalizer.stripIntroBlock(raw);

      expect(normalized, '本文1行目\n本文2行目');
    });

    test('keeps text unchanged when intro block does not exist', () {
      const raw = '本文のみ\n2行目';

      final normalized = AozoraTextNormalizer.stripIntroBlock(raw);

      expect(normalized, raw);
    });
  });
}
