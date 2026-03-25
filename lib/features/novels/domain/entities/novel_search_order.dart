enum NovelSearchOrder {
  newest,
  overallPoint,
  dailyPoint,
  weeklyPoint,
  monthlyPoint,
  quarterlyPoint,
  yearlyPoint,
}

extension NovelSearchOrderX on NovelSearchOrder {
  static const List<NovelSearchOrder> selectableValues = <NovelSearchOrder>[
    NovelSearchOrder.newest,
    NovelSearchOrder.dailyPoint,
    NovelSearchOrder.weeklyPoint,
    NovelSearchOrder.monthlyPoint,
    NovelSearchOrder.quarterlyPoint,
    NovelSearchOrder.yearlyPoint,
    NovelSearchOrder.overallPoint,
  ];

  String get queryValue {
    return switch (this) {
      NovelSearchOrder.newest => 'new',
      NovelSearchOrder.overallPoint => 'overall',
      NovelSearchOrder.dailyPoint => 'daily',
      NovelSearchOrder.weeklyPoint => 'weekly',
      NovelSearchOrder.monthlyPoint => 'monthly',
      NovelSearchOrder.quarterlyPoint => 'quarterly',
      NovelSearchOrder.yearlyPoint => 'yearly',
    };
  }

  String get label {
    return switch (this) {
      NovelSearchOrder.newest => '新着',
      NovelSearchOrder.overallPoint => '総合',
      NovelSearchOrder.dailyPoint => '日間',
      NovelSearchOrder.weeklyPoint => '週間',
      NovelSearchOrder.monthlyPoint => '月間',
      NovelSearchOrder.quarterlyPoint => '四半期',
      NovelSearchOrder.yearlyPoint => '年間',
    };
  }

  static NovelSearchOrder fromQueryValue(String? value) {
    return switch (value) {
      'overall' => NovelSearchOrder.overallPoint,
      'daily' => NovelSearchOrder.dailyPoint,
      'weekly' => NovelSearchOrder.weeklyPoint,
      'monthly' => NovelSearchOrder.monthlyPoint,
      'quarterly' => NovelSearchOrder.quarterlyPoint,
      'yearly' => NovelSearchOrder.yearlyPoint,
      _ => NovelSearchOrder.newest,
    };
  }
}
