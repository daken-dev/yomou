import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:kumihan/kumihan.dart' as kumi;
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/narou/data/narou_kumihan_parser.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

void main() {
  test(
    'NarouKumihanParser resolves linked images and separates sections with rules',
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
      final paragraphs = _paragraphs(parsed);

      expect(parsed.headerTitle, '作品 / 地図');
      expect(_paragraphText(paragraphs.first), '地図');
      expect(
        _hasHeading(paragraphs.first, kumi.AstHeadingLevel.medium),
        isTrue,
      );
      expect(
        paragraphs.where((paragraph) => _paragraphText(paragraph) == '――――'),
        hasLength(2),
      );
      expect(
        paragraphs.any((paragraph) => _paragraphText(paragraph) == '前書き'),
        isFalse,
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
      final paragraphs = _paragraphs(parsed);

      expect(_paragraphText(paragraphs[0]), '作品');
      expect(_hasHeading(paragraphs[0], kumi.AstHeadingLevel.large), isTrue);
      expect(_paragraphText(paragraphs[2]), '作者');

      final contentParagraphs = paragraphs.sublist(5);
      expect(_paragraphText(contentParagraphs[0]), '第12話');
      expect(_containsTcyText(contentParagraphs[0], '12'), isTrue);
      expect(_paragraphText(contentParagraphs[1]), '――――');
      expect(_paragraphText(contentParagraphs[2]), '第34話');
      expect(_containsTcyText(contentParagraphs[2], '34'), isTrue);
      expect(_paragraphText(contentParagraphs[3]), '123');
      expect(_containsTcyText(contentParagraphs[3], '123'), isFalse);
      expect(_paragraphText(contentParagraphs[4]), '――――');
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
    final paragraphs = _paragraphs(parsed);

    expect(paragraphs, hasLength(1));
    expect(_paragraphText(paragraphs.single), '本文です。');
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

    final paragraphs = _paragraphs(parsed);
    expect(
      paragraphs.where((paragraph) => _paragraphText(paragraph) == '本文です。'),
      hasLength(1),
    );
  });
}

List<List<kumi.AstToken>> _paragraphs(kumi.Document document) {
  final paragraphs = <List<kumi.AstToken>>[];
  var current = <kumi.AstToken>[];

  for (final token in document.ast) {
    if (token is kumi.AstNewLine) {
      paragraphs.add(current);
      current = <kumi.AstToken>[];
      continue;
    }
    current.add(token);
  }

  paragraphs.add(current);
  return paragraphs;
}

String _paragraphText(List<kumi.AstToken> tokens) {
  final buffer = StringBuffer();
  for (final token in tokens) {
    if (token case kumi.AstText(text: final text)) {
      buffer.write(text);
    }
  }
  return buffer.toString();
}

bool _hasHeading(List<kumi.AstToken> tokens, kumi.AstHeadingLevel level) {
  return tokens.any(
    (token) =>
        token is kumi.AstHeading &&
        token.level == level &&
        token.boundary == kumi.AstRangeBoundary.start,
  );
}

bool _containsTcyText(List<kumi.AstToken> tokens, String text) {
  for (var index = 0; index < tokens.length - 2; index += 1) {
    final start = tokens[index];
    final middle = tokens[index + 1];
    final end = tokens[index + 2];
    if (start is kumi.AstInlineDecoration &&
        start.kind == kumi.AstInlineDecorationKind.tatechuyoko &&
        start.boundary == kumi.AstRangeBoundary.start &&
        middle is kumi.AstText &&
        middle.text == text &&
        end is kumi.AstInlineDecoration &&
        end.kind == kumi.AstInlineDecorationKind.tatechuyoko &&
        end.boundary == kumi.AstRangeBoundary.end) {
      return true;
    }
  }
  return false;
}
