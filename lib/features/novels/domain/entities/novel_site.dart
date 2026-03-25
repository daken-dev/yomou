enum NovelSite { narou, aozora }

extension NovelSiteX on NovelSite {
  String get displayName {
    return switch (this) {
      NovelSite.narou => 'なろう',
      NovelSite.aozora => '青空文庫',
    };
  }
}
