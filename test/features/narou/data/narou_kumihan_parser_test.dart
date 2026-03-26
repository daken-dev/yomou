import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:kumihan/kumihan.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/narou/data/narou_kumihan_parser.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

void main() {
  test(
    'NarouKumihanParser unwraps linked images and separates sections with rules',
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

      // 2話目以降: エピソードタイトルのみ表示
      final firstParagraph =
          parsed.blocks.first as KumihanParagraphBlock;
      expect(_paragraphText(firstParagraph.children), '地図');
      expect(firstParagraph.children.single, isA<KumihanStyledInline>());

      expect(
        parsed.blocks.whereType<KumihanParagraphBlock>().where((block) {
          return _paragraphText(block.children) == '――――';
        }),
        hasLength(2),
      );
      expect(
        parsed.blocks.whereType<KumihanParagraphBlock>().any((block) {
          return _paragraphText(block.children) == '前書き';
        }),
        isFalse,
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

  test(
    'NarouKumihanParser normalizes obvious separators and two-digit numbers',
    () {
      const page = NarouEpisodePage(
        url: 'https://ncode.syosetu.com/n0000aa/1/',
        novelTitle: '作品',
        novelUrl: 'https://ncode.syosetu.com/n0000aa/',
        authorName: '作者',
        authorUrl: 'https://mypage.syosetu.com/1/',
        sequence: '1 / 1',
        sequenceCurrent: 1,
        sequenceTotal: 1,
        title: '一話',
        preface: null,
        prefaceHtml: null,
        body: '第12話\n----\n第３４話\n123\n====',
        bodyHtml: null,
        afterword: null,
        afterwordHtml: null,
        tocUrl: 'https://ncode.syosetu.com/n0000aa/',
        prevUrl: null,
        nextUrl: null,
      );

      final parsed = const NarouKumihanParser().parseEpisode(page);
      final paragraphs = parsed.blocks
          .whereType<KumihanParagraphBlock>()
          .toList();

      // 短編ヘッダー: 作品タイトル + 空行 + 作者名 + 空行 + 空行
      expect(_paragraphText(paragraphs[0].children), '作品');
      expect(paragraphs[0].children.single, isA<KumihanStyledInline>());
      expect(_paragraphText(paragraphs[2].children), '作者');

      // 本文コンテンツ（ヘッダー5ブロック分オフセット）
      final contentParagraphs = paragraphs.sublist(5);

      expect(_paragraphText(contentParagraphs[0].children), '第12話');
      expect(
        _findTcy(contentParagraphs[0].children)?.children.single,
        isA<KumihanTextInline>(),
      );
      expect(
        (_findTcy(contentParagraphs[0].children)?.children.single
                as KumihanTextInline)
            .text,
        '12',
      );

      expect(_paragraphText(contentParagraphs[1].children), '――――');

      expect(_paragraphText(contentParagraphs[2].children), '第34話');
      expect(
        (_findTcy(contentParagraphs[2].children)?.children.single
                as KumihanTextInline)
            .text,
        '34',
      );

      expect(contentParagraphs[3].children, hasLength(1));
      expect(contentParagraphs[3].children.single, isA<KumihanTextInline>());
      expect(
        (contentParagraphs[3].children.single as KumihanTextInline).text,
        '123',
      );

      expect(_paragraphText(contentParagraphs[4].children), '――――');
    },
  );

  test('NarouKumihanParser trims visually blank trailing paragraphs', () {
    final document = html_parser.parse('''
      <html>
        <body>
          <div class="p-novel__body">
            <div class="p-novel__text">
              <p>本文です。</p>
              <p>　</p>
              <p> </p>
            </div>
          </div>
        </body>
      </html>
    ''');

    final page = NarouEpisodePage.fromDocument(
      url: 'https://ncode.syosetu.com/n0000aa/1/',
      document: document,
    );
    final parsed = const NarouKumihanParser().parseEpisode(page);
    final paragraphs = parsed.blocks
        .whereType<KumihanParagraphBlock>()
        .toList();

    expect(paragraphs, hasLength(1));
    expect(_paragraphText(paragraphs.single.children), '本文です。');
  });

  test('NarouKumihanParser can hide preface and afterword', () {
    const page = NarouEpisodePage(
      url: 'https://ncode.syosetu.com/n0000aa/1/',
      novelTitle: '作品',
      novelUrl: 'https://ncode.syosetu.com/n0000aa/',
      authorName: '作者',
      authorUrl: 'https://mypage.syosetu.com/1/',
      sequence: '1 / 1',
      sequenceCurrent: 1,
      sequenceTotal: 1,
      title: '一話',
      preface: '前書きです。',
      prefaceHtml: null,
      body: '本文です。',
      bodyHtml: null,
      afterword: 'あとがきです。',
      afterwordHtml: null,
      tocUrl: 'https://ncode.syosetu.com/n0000aa/',
      prevUrl: null,
      nextUrl: null,
    );

    final parsed = const NarouKumihanParser().parseEpisode(
      page,
      settings: const ReaderSettings.defaults().copyWith(
        showPreface: false,
        showAfterword: false,
      ),
    );
    final paragraphs = parsed.blocks
        .whereType<KumihanParagraphBlock>()
        .toList(growable: false);

    // 短編ヘッダー(5ブロック) + 本文(1ブロック)
    final contentParagraphs = paragraphs
        .where((p) => _paragraphText(p.children) == '本文です。')
        .toList();
    expect(contentParagraphs, hasLength(1));
  });
}

String _paragraphText(List<KumihanInline> children) {
  final buffer = StringBuffer();
  for (final child in children) {
    switch (child) {
      case KumihanTextInline():
        buffer.write(child.text);
        break;
      case KumihanStyledInline():
        buffer.write(_paragraphText(child.children));
        break;
      case KumihanLinkInline():
        buffer.write(_paragraphText(child.children));
        break;
      case KumihanRubyInline():
        buffer.write(_paragraphText(child.children));
        break;
      default:
        break;
    }
  }
  return buffer.toString();
}

KumihanStyledInline? _findTcy(List<KumihanInline> children) {
  for (final child in children) {
    switch (child) {
      case KumihanStyledInline() when child.style == '縦中横':
        return child;
      case KumihanStyledInline():
        final nested = _findTcy(child.children);
        if (nested != null) {
          return nested;
        }
        break;
      case KumihanLinkInline():
        final nested = _findTcy(child.children);
        if (nested != null) {
          return nested;
        }
        break;
      case KumihanRubyInline():
        final nested = _findTcy(child.children);
        if (nested != null) {
          return nested;
        }
        break;
      default:
        break;
    }
  }
  return null;
}
