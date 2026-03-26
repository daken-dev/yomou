enum NovelupGenre {
  highFantasy(1, '異世界ファンタジー'),
  lowFantasy(2, '現代/その他ファンタジー'),
  sf(3, 'SF'),
  romance(4, '恋愛/ラブコメ'),
  horror(5, 'ホラー'),
  mystery(6, 'ミステリー'),
  essay(7, 'エッセイ/評論/コラム'),
  history(8, '歴史/時代'),
  literature(9, '文芸/純文学'),
  blog(10, 'ブログ/活動報告'),
  youthDrama(11, '現代/青春ドラマ'),
  poem(12, '詩/短歌'),
  pickup(13, 'ノベプラ掲載作品紹介'),
  comedy(14, 'コメディ/ギャグ'),
  secondaryCreation(52, '二次創作'),
  others(99, '童話/絵本/その他');

  const NovelupGenre(this.code, this.label);

  final int code;
  final String label;

  static NovelupGenre? fromCode(int code) {
    for (final genre in values) {
      if (genre.code == code) {
        return genre;
      }
    }
    return null;
  }

  static String labelOfCode(int code) {
    return fromCode(code)?.label ?? 'ジャンル$code';
  }
}
