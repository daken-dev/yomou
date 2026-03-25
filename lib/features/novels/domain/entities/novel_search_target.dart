enum NovelSearchTarget { all, title, story, keyword, author }

extension NovelSearchTargetX on NovelSearchTarget {
  static const List<NovelSearchTarget> selectableValues = <NovelSearchTarget>[
    NovelSearchTarget.all,
    NovelSearchTarget.title,
    NovelSearchTarget.story,
    NovelSearchTarget.keyword,
    NovelSearchTarget.author,
  ];

  String get queryValue {
    return switch (this) {
      NovelSearchTarget.all => 'all',
      NovelSearchTarget.title => 'title',
      NovelSearchTarget.story => 'story',
      NovelSearchTarget.keyword => 'keyword',
      NovelSearchTarget.author => 'author',
    };
  }

  String get label {
    return switch (this) {
      NovelSearchTarget.all => 'すべて',
      NovelSearchTarget.title => 'タイトル',
      NovelSearchTarget.story => 'あらすじ',
      NovelSearchTarget.keyword => 'キーワード',
      NovelSearchTarget.author => '作者名',
    };
  }

  static NovelSearchTarget fromQueryValue(String? value) {
    return switch (value) {
      'title' => NovelSearchTarget.title,
      'story' => NovelSearchTarget.story,
      'keyword' => NovelSearchTarget.keyword,
      'author' => NovelSearchTarget.author,
      _ => NovelSearchTarget.all,
    };
  }
}
