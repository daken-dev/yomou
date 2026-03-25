import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:kumihan/kumihan.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/narou/data/narou_kumihan_parser.dart';

void main() {
  test(
    'NarouKumihanParser unwraps linked images and keeps section headings',
    () {
      final document = html_parser.parse('''
      <html>
        <body>
          <div class="c-announce-box">
            <div class="c-announce">
              <a href="/n6316bn/">作品</a>
              <a href="https://mypage.syosetu.com/1/">作者</a>
            </div>
          </div>
          <div class="p-novel__number">47/304</div>
          <h1 class="p-novel__title">地図</h1>
          <div class="p-novel__body">
            <div class="p-novel__text p-novel__text--preface">
              <p id="Lp1">　前書きです。</p>
            </div>
            <div class="p-novel__text">
              <p id="L1">　本文です。</p>
              <p id="L2">
                <a href="//8371.mitemin.net/i71781/" target="_blank">
                  <img src="//8371.mitemin.net/userpageimage/viewimagebig/icode/i71781/" />
                </a>
              </p>
            </div>
            <div class="p-novel__text p-novel__text--afterword">
              <p id="La1">　あとがきです。</p>
            </div>
          </div>
          <div class="c-pager c-pager--center">
            <a class="c-pager__item" href="/n6316bn/46/">前へ</a>
            <a class="c-pager__item" href="/n6316bn/">目次</a>
            <a class="c-pager__item" href="/n6316bn/48/">次へ</a>
          </div>
        </body>
      </html>
    ''');

      final page = NarouEpisodePage.fromDocument(
        url: 'https://ncode.syosetu.com/n6316bn/47/',
        document: document,
      );
      final parsed = const NarouKumihanParser().parseEpisode(page);

      expect(parsed.headerTitle, '作品 / 地図');
      expect(parsed.blocks.first, isA<KumihanParagraphBlock>());
      expect(
        (parsed.blocks.first as KumihanParagraphBlock).children.single,
        isA<KumihanStyledInline>(),
      );

      final imageBlock = parsed.blocks
          .whereType<KumihanParagraphBlock>()
          .firstWhere(
            (block) =>
                block.children.any((child) => child is KumihanImageInline),
          );
      final image = imageBlock.children.whereType<KumihanImageInline>().single;
      expect(
        image.path,
        'https://8371.mitemin.net/userpageimage/viewimagebig/icode/i71781/',
      );
    },
  );
}
