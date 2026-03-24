enum NovelSite { narou }

extension NovelSiteX on NovelSite {
  String get displayName {
    return switch (this) {
      NovelSite.narou => 'なろう',
    };
  }
}
