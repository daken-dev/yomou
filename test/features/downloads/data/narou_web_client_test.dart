import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:yomou/features/downloads/data/narou_web_client.dart';

void main() {
  test('NarouTocPage synthesizes a single episode for short stories', () {
    final document = html_parser.parse('''
      <html>
        <body>
          <h1 class="p-novel__title">短編作品</h1>
          <div class="p-novel__author">
            <a href="https://example.com/users/1">作者</a>
          </div>
          <div class="p-novel__body">
            <div class="p-novel__text">本文</div>
          </div>
        </body>
      </html>
    ''');

    const infoPage = NarouInfoPage(
      url: 'https://ncode.syosetu.com/novelview/infotop/ncode/n0001aa/',
      title: '短編作品',
      authorUrl: 'https://example.com/users/1',
      fields: <String, String>{
        '作者名': '作者',
        '掲載日': '2026/03/24',
        '最終更新日': '2026/03/25',
        'あらすじ': '短編あらすじ',
      },
      kasasagiUrl: null,
      workUrl: null,
      qrcodeUrl: null,
    );

    final page = NarouTocPage.fromDocument(
      url: 'https://ncode.syosetu.com/n0001aa/',
      document: document,
      shortStoryInfoPage: infoPage,
    );

    expect(page.title, '短編作品');
    expect(page.authorName, '作者');
    expect(page.summary, '短編あらすじ');
    expect(page.latestEpisodePublished, '2026/03/24');
    expect(page.lastPage, 1);
    expect(page.entries, hasLength(1));

    final entry = page.entries.single;
    expect(entry.type, NarouTocEntryType.episode);
    expect(entry.episodeNo, 1);
    expect(entry.title, '短編作品');
    expect(entry.url, 'https://ncode.syosetu.com/n0001aa/');
    expect(entry.publishedAt, '2026/03/24');
    expect(entry.revisedAt, '2026/03/25');
  });

  test('NarouEpisodePage treats short stories as 1/1 episodes', () {
    final document = html_parser.parse('''
      <html>
        <body>
          <h1 class="p-novel__title">短編本文</h1>
          <div class="p-novel__author">
            <a href="https://example.com/users/1">作者</a>
          </div>
          <div class="p-novel__body">
            <div class="p-novel__text p-novel__text--preface">前書き</div>
            <div class="p-novel__text">本文1行目</div>
            <div class="p-novel__text p-novel__text--afterword">後書き</div>
          </div>
        </body>
      </html>
    ''');

    final page = NarouEpisodePage.fromDocument(
      url: 'https://ncode.syosetu.com/n0001aa/',
      document: document,
    );

    expect(page.novelTitle, '短編本文');
    expect(page.novelUrl, 'https://ncode.syosetu.com/n0001aa/');
    expect(page.authorName, '作者');
    expect(page.authorUrl, 'https://example.com/users/1');
    expect(page.sequence, '1 / 1');
    expect(page.sequenceCurrent, 1);
    expect(page.sequenceTotal, 1);
    expect(page.tocUrl, 'https://ncode.syosetu.com/n0001aa/');
    expect(page.prevUrl, isNull);
    expect(page.nextUrl, isNull);
    expect(page.preface, '前書き');
    expect(page.body, '本文1行目');
    expect(page.afterword, '後書き');
  });
}
