enum NovelRankingPeriod { daily, weekly, monthly, quarterly, yearly }

extension NovelRankingPeriodX on NovelRankingPeriod {
  String get displayName {
    return switch (this) {
      NovelRankingPeriod.daily => '日刊ランキング',
      NovelRankingPeriod.weekly => '週間ランキング',
      NovelRankingPeriod.monthly => '月間ランキング',
      NovelRankingPeriod.quarterly => '四半期ランキング',
      NovelRankingPeriod.yearly => '年間ランキング',
    };
  }
}
