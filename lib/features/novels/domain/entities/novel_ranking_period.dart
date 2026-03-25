enum NovelRankingPeriod { overall, daily, weekly, monthly, quarterly, yearly }

extension NovelRankingPeriodX on NovelRankingPeriod {
  static const List<NovelRankingPeriod> selectableValues = <NovelRankingPeriod>[
    NovelRankingPeriod.daily,
    NovelRankingPeriod.weekly,
    NovelRankingPeriod.monthly,
    NovelRankingPeriod.quarterly,
    NovelRankingPeriod.yearly,
    NovelRankingPeriod.overall,
  ];

  String get queryValue {
    return switch (this) {
      NovelRankingPeriod.overall => 'overall',
      NovelRankingPeriod.daily => 'daily',
      NovelRankingPeriod.weekly => 'weekly',
      NovelRankingPeriod.monthly => 'monthly',
      NovelRankingPeriod.quarterly => 'quarterly',
      NovelRankingPeriod.yearly => 'yearly',
    };
  }

  String get label {
    return switch (this) {
      NovelRankingPeriod.overall => '総合',
      NovelRankingPeriod.daily => '日間',
      NovelRankingPeriod.weekly => '週間',
      NovelRankingPeriod.monthly => '月間',
      NovelRankingPeriod.quarterly => '四半期',
      NovelRankingPeriod.yearly => '年間',
    };
  }

  String get displayName {
    return switch (this) {
      NovelRankingPeriod.overall => '総合ランキング',
      NovelRankingPeriod.daily => '日刊ランキング',
      NovelRankingPeriod.weekly => '週間ランキング',
      NovelRankingPeriod.monthly => '月間ランキング',
      NovelRankingPeriod.quarterly => '四半期ランキング',
      NovelRankingPeriod.yearly => '年間ランキング',
    };
  }

  static NovelRankingPeriod fromQueryValue(String? value) {
    return switch (value) {
      'overall' => NovelRankingPeriod.overall,
      'weekly' => NovelRankingPeriod.weekly,
      'monthly' => NovelRankingPeriod.monthly,
      'quarterly' => NovelRankingPeriod.quarterly,
      'yearly' => NovelRankingPeriod.yearly,
      _ => NovelRankingPeriod.daily,
    };
  }
}
