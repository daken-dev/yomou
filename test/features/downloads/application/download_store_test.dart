import 'package:flutter_test/flutter_test.dart';
import 'package:yomou/core/database/app_database.dart';
import 'package:yomou/features/downloads/data/download_store.dart';
import 'package:yomou/features/downloads/data/narou_web_client.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

void main() {
  test('removeNovel deletes saved novel and cascades related data', () async {
    final database = AppDatabase(pathProvider: () async => ':memory:');
    addTearDown(database.dispose);

    final store = DownloadStore(database);
    const novel = NovelSummary(
      site: NovelSite.narou,
      id: 'N0001AA',
      title: '作品1',
    );

    await store.saveNovel(novel);
    await store.enqueueSyncNovel(
      site: novel.site,
      novelId: novel.id,
      priority: 100,
    );

    expect(await store.hasSavedNovel(novel.site, novel.id), isTrue);
    expect(await store.listSavedNovelIds(novel.site), {'N0001AA'});

    await store.removeNovel(novel.site, novel.id);

    expect(await store.hasSavedNovel(novel.site, novel.id), isFalse);
    expect(await store.listSavedNovelIds(novel.site), isEmpty);
    expect(await store.listSavedNovels(), isEmpty);
    expect(await store.listRecentJobs(), isEmpty);
  });

  test('applyNovelSync locks updates when episode count decreases', () async {
    final database = AppDatabase(pathProvider: () async => ':memory:');
    addTearDown(database.dispose);

    final fixedNow = DateTime.utc(2026, 3, 25, 0, 0, 0);
    final store = DownloadStore(database, now: () => fixedNow);
    const novel = NovelSummary(
      site: NovelSite.narou,
      id: 'N0001AA',
      title: '作品1',
    );

    await store.saveNovel(novel);

    final firstResult = await store.applyNovelSync(
      site: novel.site,
      novelId: novel.id,
      fallbackTitle: novel.title,
      infoPage: const NarouInfoPage(
        url: 'https://ncode.syosetu.com/novelview/infotop/ncode/n0001aa/',
        title: '作品1',
        authorUrl: 'https://example.com/authors/1',
        fields: <String, String>{'作者名': '作者1'},
        kasasagiUrl: null,
        workUrl: null,
        qrcodeUrl: null,
      ),
      tocPages: <NarouTocPage>[
        NarouTocPage(
          url: 'https://ncode.syosetu.com/n0001aa/',
          page: 1,
          title: '作品1',
          authorName: '作者1',
          authorUrl: 'https://example.com/authors/1',
          summary: 'あらすじ',
          summaryHtml: '<p>あらすじ</p>',
          latestEpisodePublished: '2026/03/25',
          lastPage: 1,
          lastPageUrl: null,
          entries: <NarouTocEntry>[
            NarouTocEntry.chapter(title: '第一章', indexPage: 1),
            NarouTocEntry.episode(
              episodeNo: 1,
              title: '1話',
              url: 'https://ncode.syosetu.com/n0001aa/1/',
              indexPage: 1,
            ),
            NarouTocEntry.episode(
              episodeNo: 2,
              title: '2話',
              url: 'https://ncode.syosetu.com/n0001aa/2/',
              indexPage: 1,
            ),
          ],
        ),
      ],
      force: false,
      refreshInterval: const Duration(hours: 1),
    );

    expect(firstResult.isLocked, isFalse);
    expect(firstResult.downloadPlans.length, 2);
    expect(firstResult.downloadPlans.first.priority, greaterThan(0));

    final lockedResult = await store.applyNovelSync(
      site: novel.site,
      novelId: novel.id,
      fallbackTitle: novel.title,
      infoPage: const NarouInfoPage(
        url: 'https://ncode.syosetu.com/novelview/infotop/ncode/n0001aa/',
        title: '作品1',
        authorUrl: 'https://example.com/authors/1',
        fields: <String, String>{'作者名': '作者1'},
        kasasagiUrl: null,
        workUrl: null,
        qrcodeUrl: null,
      ),
      tocPages: <NarouTocPage>[
        NarouTocPage(
          url: 'https://ncode.syosetu.com/n0001aa/',
          page: 1,
          title: '作品1',
          authorName: '作者1',
          authorUrl: 'https://example.com/authors/1',
          summary: 'あらすじ',
          summaryHtml: '<p>あらすじ</p>',
          latestEpisodePublished: '2026/03/25',
          lastPage: 1,
          lastPageUrl: null,
          entries: <NarouTocEntry>[
            NarouTocEntry.chapter(title: '第一章', indexPage: 1),
            NarouTocEntry.episode(
              episodeNo: 1,
              title: '1話',
              url: 'https://ncode.syosetu.com/n0001aa/1/',
              indexPage: 1,
            ),
          ],
        ),
      ],
      force: false,
      refreshInterval: const Duration(hours: 1),
    );

    expect(lockedResult.isLocked, isTrue);
    expect(lockedResult.lockReason, contains('話数が減少'));

    final overview = (await store.listSavedNovels()).single;
    expect(overview.state, SavedNovelSyncState.locked);
    expect(overview.lockReason, contains('話数が減少'));
  });

  test(
    'saveReadingProgress stores resume page and remaining episodes',
    () async {
      final database = AppDatabase(pathProvider: () async => ':memory:');
      addTearDown(database.dispose);

      final store = DownloadStore(database);
      const novel = NovelSummary(
        site: NovelSite.narou,
        id: 'N0001AA',
        title: '作品1',
      );

      await store.saveNovel(novel);
      await store.applyNovelSync(
        site: novel.site,
        novelId: novel.id,
        fallbackTitle: novel.title,
        infoPage: const NarouInfoPage(
          url: 'https://ncode.syosetu.com/novelview/infotop/ncode/n0001aa/',
          title: '作品1',
          authorUrl: 'https://example.com/authors/1',
          fields: <String, String>{'作者名': '作者1'},
          kasasagiUrl: null,
          workUrl: null,
          qrcodeUrl: null,
        ),
        tocPages: <NarouTocPage>[
          NarouTocPage(
            url: 'https://ncode.syosetu.com/n0001aa/',
            page: 1,
            title: '作品1',
            authorName: '作者1',
            authorUrl: 'https://example.com/authors/1',
            summary: 'あらすじ',
            summaryHtml: '<p>あらすじ</p>',
            latestEpisodePublished: '2026/03/25',
            lastPage: 1,
            lastPageUrl: null,
            entries: <NarouTocEntry>[
              NarouTocEntry.episode(
                episodeNo: 1,
                title: '1話',
                url: 'https://ncode.syosetu.com/n0001aa/1/',
                indexPage: 1,
              ),
              NarouTocEntry.episode(
                episodeNo: 2,
                title: '2話',
                url: 'https://ncode.syosetu.com/n0001aa/2/',
                indexPage: 1,
              ),
              NarouTocEntry.episode(
                episodeNo: 3,
                title: '3話',
                url: 'https://ncode.syosetu.com/n0001aa/3/',
                indexPage: 1,
              ),
            ],
          ),
        ],
        force: false,
        refreshInterval: const Duration(hours: 1),
      );

      await store.saveReadingProgress(
        site: novel.site,
        novelId: novel.id,
        episodeNo: 2,
        pageNumber: 3,
        pageCount: 8,
        nextEpisodeNo: 3,
      );

      final overview = (await store.listSavedNovels()).single;
      expect(overview.remainingEpisodes, 2);
      expect(overview.resumeEpisodeNo, 2);
      expect(overview.resumePageNumber, 3);
      expect(overview.resumePageCount, 8);
    },
  );

  test(
    'saveReadingProgress treats the last page as completion and keeps novel done',
    () async {
      final database = AppDatabase(pathProvider: () async => ':memory:');
      addTearDown(database.dispose);

      final store = DownloadStore(database);
      const novel = NovelSummary(
        site: NovelSite.narou,
        id: 'N0001AA',
        title: '作品1',
      );

      await store.saveNovel(novel);
      await store.applyNovelSync(
        site: novel.site,
        novelId: novel.id,
        fallbackTitle: novel.title,
        infoPage: const NarouInfoPage(
          url: 'https://ncode.syosetu.com/novelview/infotop/ncode/n0001aa/',
          title: '作品1',
          authorUrl: 'https://example.com/authors/1',
          fields: <String, String>{'作者名': '作者1'},
          kasasagiUrl: null,
          workUrl: null,
          qrcodeUrl: null,
        ),
        tocPages: <NarouTocPage>[
          NarouTocPage(
            url: 'https://ncode.syosetu.com/n0001aa/',
            page: 1,
            title: '作品1',
            authorName: '作者1',
            authorUrl: 'https://example.com/authors/1',
            summary: 'あらすじ',
            summaryHtml: '<p>あらすじ</p>',
            latestEpisodePublished: '2026/03/25',
            lastPage: 1,
            lastPageUrl: null,
            entries: <NarouTocEntry>[
              NarouTocEntry.episode(
                episodeNo: 1,
                title: '1話',
                url: 'https://ncode.syosetu.com/n0001aa/1/',
                indexPage: 1,
              ),
              NarouTocEntry.episode(
                episodeNo: 2,
                title: '2話',
                url: 'https://ncode.syosetu.com/n0001aa/2/',
                indexPage: 1,
              ),
            ],
          ),
        ],
        force: false,
        refreshInterval: const Duration(hours: 1),
      );

      await store.saveReadingProgress(
        site: novel.site,
        novelId: novel.id,
        episodeNo: 2,
        pageNumber: 8,
        pageCount: 8,
      );

      var overview = (await store.listSavedNovels()).single;
      expect(overview.remainingEpisodes, 0);
      expect(overview.resumeEpisodeNo, 3);
      expect(overview.resumePageCount, 0);

      await store.applyNovelSync(
        site: novel.site,
        novelId: novel.id,
        fallbackTitle: novel.title,
        infoPage: const NarouInfoPage(
          url: 'https://ncode.syosetu.com/novelview/infotop/ncode/n0001aa/',
          title: '作品1',
          authorUrl: 'https://example.com/authors/1',
          fields: <String, String>{'作者名': '作者1'},
          kasasagiUrl: null,
          workUrl: null,
          qrcodeUrl: null,
        ),
        tocPages: <NarouTocPage>[
          NarouTocPage(
            url: 'https://ncode.syosetu.com/n0001aa/',
            page: 1,
            title: '作品1',
            authorName: '作者1',
            authorUrl: 'https://example.com/authors/1',
            summary: 'あらすじ',
            summaryHtml: '<p>あらすじ</p>',
            latestEpisodePublished: '2026/03/25',
            lastPage: 1,
            lastPageUrl: null,
            entries: <NarouTocEntry>[
              NarouTocEntry.episode(
                episodeNo: 1,
                title: '1話',
                url: 'https://ncode.syosetu.com/n0001aa/1/',
                indexPage: 1,
              ),
              NarouTocEntry.episode(
                episodeNo: 2,
                title: '2話',
                url: 'https://ncode.syosetu.com/n0001aa/2/',
                indexPage: 1,
              ),
              NarouTocEntry.episode(
                episodeNo: 3,
                title: '3話',
                url: 'https://ncode.syosetu.com/n0001aa/3/',
                indexPage: 1,
              ),
            ],
          ),
        ],
        force: false,
        refreshInterval: const Duration(hours: 1),
      );

      overview = (await store.listSavedNovels()).single;
      expect(overview.remainingEpisodes, 1);
      expect(overview.resumeEpisodeNo, 3);
    },
  );
}
