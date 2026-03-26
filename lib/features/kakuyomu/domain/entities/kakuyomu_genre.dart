class KakuyomuGenre {
  const KakuyomuGenre({
    required this.code,
    required this.slug,
    required this.label,
  });

  final int code;
  final String slug;
  final String label;

  static const List<KakuyomuGenre> values = <KakuyomuGenre>[
    KakuyomuGenre(code: 1, slug: 'fantasy', label: '異世界ファンタジー'),
    KakuyomuGenre(code: 2, slug: 'contemporary_fantasy', label: '現代ファンタジー'),
    KakuyomuGenre(code: 3, slug: 'sf', label: 'SF'),
    KakuyomuGenre(code: 4, slug: 'romance', label: '恋愛'),
    KakuyomuGenre(code: 5, slug: 'love_comedy', label: 'ラブコメ'),
    KakuyomuGenre(code: 6, slug: 'contemporary_drama', label: '現代ドラマ'),
    KakuyomuGenre(code: 7, slug: 'horror', label: 'ホラー'),
    KakuyomuGenre(code: 8, slug: 'mystery', label: 'ミステリー'),
    KakuyomuGenre(code: 9, slug: 'essay_nonfiction', label: 'エッセイ・ノンフィクション'),
    KakuyomuGenre(code: 10, slug: 'history_period_legend', label: '歴史・時代・伝奇'),
    KakuyomuGenre(code: 11, slug: 'creation_theory_criticism', label: '創作論・評論'),
    KakuyomuGenre(
      code: 12,
      slug: 'poetry_fairy_tale_others',
      label: '詩・童話・その他',
    ),
    KakuyomuGenre(code: 13, slug: 'maho_no_iland', label: '魔法のiらんど'),
    KakuyomuGenre(code: 14, slug: 'derivative_work', label: '二次創作'),
  ];

  static KakuyomuGenre? fromCode(int code) {
    for (final genre in values) {
      if (genre.code == code) {
        return genre;
      }
    }
    return null;
  }

  static KakuyomuGenre? fromSlug(String slug) {
    for (final genre in values) {
      if (genre.slug == slug) {
        return genre;
      }
    }
    return null;
  }

  static String labelOfCode(int code) {
    return fromCode(code)?.label ?? 'ジャンル不明';
  }

  static String labelOfSlug(String? slug) {
    if (slug == null || slug.isEmpty) {
      return '';
    }
    return fromSlug(slug)?.label ?? slug;
  }
}
