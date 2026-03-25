class NarouGenre {
  const NarouGenre({required this.code, required this.label});

  final int code;
  final String label;

  static const List<NarouGenre> values = <NarouGenre>[
    NarouGenre(code: 101, label: '異世界〔恋愛〕'),
    NarouGenre(code: 102, label: '現実世界〔恋愛〕'),
    NarouGenre(code: 201, label: 'ハイファンタジー'),
    NarouGenre(code: 202, label: 'ローファンタジー'),
    NarouGenre(code: 301, label: '純文学'),
    NarouGenre(code: 302, label: 'ヒューマンドラマ'),
    NarouGenre(code: 303, label: '歴史'),
    NarouGenre(code: 304, label: '推理'),
    NarouGenre(code: 305, label: 'ホラー'),
    NarouGenre(code: 306, label: 'アクション'),
    NarouGenre(code: 307, label: 'コメディー'),
    NarouGenre(code: 401, label: 'VRゲーム〔SF〕'),
    NarouGenre(code: 402, label: '宇宙〔SF〕'),
    NarouGenre(code: 403, label: '空想科学〔SF〕'),
    NarouGenre(code: 404, label: 'パニック〔SF〕'),
    NarouGenre(code: 9901, label: '童話'),
    NarouGenre(code: 9902, label: '詩'),
    NarouGenre(code: 9903, label: 'エッセイ'),
    NarouGenre(code: 9904, label: 'リプレイ'),
    NarouGenre(code: 9999, label: 'その他'),
    NarouGenre(code: 9801, label: 'ノンジャンル'),
  ];

  static NarouGenre? fromCode(int code) {
    for (final genre in values) {
      if (genre.code == code) {
        return genre;
      }
    }
    return null;
  }

  static String labelOf(int code) {
    return fromCode(code)?.label ?? '';
  }
}
