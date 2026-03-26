enum NovelSite { narou, narouR18, kakuyomu, novelup, hameln, aozora }

extension NovelSiteX on NovelSite {
  String get displayName {
    return switch (this) {
      NovelSite.narou => 'なろう',
      NovelSite.narouR18 => 'なろうR18',
      NovelSite.kakuyomu => 'カクヨム',
      NovelSite.novelup => 'ノベルアップ+',
      NovelSite.hameln => 'ハーメルン',
      NovelSite.aozora => '青空文庫',
    };
  }

  String get routePrefix {
    return switch (this) {
      NovelSite.narou => '/narou',
      NovelSite.narouR18 => '/narou-r18',
      NovelSite.kakuyomu => '/kakuyomu',
      NovelSite.novelup => '/novelup',
      NovelSite.hameln => '/hameln',
      NovelSite.aozora => '/aozora',
    };
  }

  String? get workHost {
    return switch (this) {
      NovelSite.narou => 'ncode.syosetu.com',
      NovelSite.narouR18 => 'novel18.syosetu.com',
      NovelSite.kakuyomu => null,
      NovelSite.novelup => null,
      NovelSite.hameln => null,
      NovelSite.aozora => null,
    };
  }
}
