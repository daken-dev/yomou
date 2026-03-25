import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/features/aozora/data/aozora_index_client.dart';

void main() {
  group('AozoraIndexClient.parseRowsForTest', () {
    test(
      'extracts multiple works and keeps zip URLs even when embedded in text',
      () {
        final client = AozoraIndexClient(Dio());
        final rows = <List<dynamic>>[
          <dynamic>['作品ID', '作品名', '著者名', '図書カードURL', 'テキストファイルURL', '役割フラグ'],
          <dynamic>[
            '48361',
            '眞間名所',
            '阪井久良伎',
            'https://www.aozora.gr.jp/cards/001337/card48361.html',
            'https://www.aozora.gr.jp/cards/001337/files/48361_ruby_42322.zip',
            '著者',
          ],
          <dynamic>[
            '',
            '別作品',
            '別著者',
            'https://www.aozora.gr.jp/cards/000001/card99999.html',
            '<a href="https://www.aozora.gr.jp/cards/000001/files/99999_ruby_1.zip">zip</a>',
            '著者',
          ],
        ];

        final works = client.parseRowsForTest(rows);

        expect(works.length, 2);
        expect(
          works.any((work) => work.id == '48361' && work.title == '眞間名所'),
          isTrue,
        );
        expect(
          works.any((work) => work.id == '99999' && work.title == '別作品'),
          isTrue,
        );
      },
    );

    test('uses exact header match before partial match', () {
      final client = AozoraIndexClient(Dio());
      final rows = <List<dynamic>>[
        <dynamic>['作品名読み', '作品名', '著者名', '図書カードURL', 'テキストファイルURL', '作品ID'],
        <dynamic>[
          'ままめいしょ',
          '眞間名所',
          '阪井久良伎',
          'https://www.aozora.gr.jp/cards/001337/card48361.html',
          'https://www.aozora.gr.jp/cards/001337/files/48361_ruby_42322.zip',
          '48361',
        ],
      ];

      final works = client.parseRowsForTest(rows);

      expect(works.length, 1);
      expect(works.first.title, '眞間名所');
      expect(works.first.id, '48361');
      expect(works.first.titleReading, 'ままめいしょ');
    });

    test('extracts rich metadata fields used by detail page', () {
      final client = AozoraIndexClient(Dio());
      final rows = <List<dynamic>>[
        <dynamic>[
          '作品ID',
          '作品名',
          '作品名読み',
          '副題',
          '副題読み',
          '原題',
          '初出',
          '分類番号',
          '文字遣い種別',
          '作品著作権フラグ',
          '公開日',
          '最終更新日',
          '図書カードURL',
          '役割フラグ',
          '生年月日',
          '没年月日',
          '人物著作権フラグ',
          '入力者',
          '校正者',
          'テキストファイルURL',
          'テキストファイル符号化方式',
          'XHTML/HTMLファイルURL',
          'XHTML/HTMLファイル符号化方式',
          '姓',
          '名',
        ],
        <dynamic>[
          '53680',
          'リップ・ヴァン・ウィンクル',
          'りっぷ・ゔぁん・うぃんくる',
          'ディードリッヒ・ニッカボッカーの遺稿',
          'でぃーどりっひ・にっかぼっかーのいこう',
          'RIP VAN WINKLE',
          '初出テキスト',
          'NDC 933',
          '新字新仮名',
          'なし',
          '2019-11-28',
          '2020-03-19',
          'https://www.aozora.gr.jp/cards/000879/card53680.html',
          '著者',
          '1892-03-01',
          '1927-07-24',
          'なし',
          '入力者A',
          '校正者B',
          'https://www.aozora.gr.jp/cards/000879/files/53680_ruby_69540.zip',
          'ShiftJIS',
          'https://www.aozora.gr.jp/cards/000879/files/53680_69591.html',
          'ShiftJIS',
          '芥川',
          '竜之介',
        ],
      ];

      final works = client.parseRowsForTest(rows);

      expect(works.length, 1);
      final work = works.first;
      expect(work.subtitleReading, 'でぃーどりっひ・にっかぼっかーのいこう');
      expect(work.originalTitle, 'RIP VAN WINKLE');
      expect(work.firstAppearance, '初出テキスト');
      expect(work.classification, 'NDC 933');
      expect(work.writingStyle, '新字新仮名');
      expect(work.workCopyright, 'なし');
      expect(work.publicationDate, '2019-11-28');
      expect(work.csvUpdatedDate, '2020-03-19');
      expect(work.role, '著者');
      expect(work.birthDate, '1892-03-01');
      expect(work.deathDate, '1927-07-24');
      expect(work.personCopyright, 'なし');
      expect(work.textEncoding, 'ShiftJIS');
      expect(
        work.htmlUrl,
        'https://www.aozora.gr.jp/cards/000879/files/53680_69591.html',
      );
      expect(work.htmlEncoding, 'ShiftJIS');
      expect(work.inputter, '入力者A');
      expect(work.proofreader, '校正者B');
    });
  });
}
