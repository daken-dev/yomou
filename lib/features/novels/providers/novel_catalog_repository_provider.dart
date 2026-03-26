import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/aozora/data/aozora_novel_catalog_repository.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/narou/data/narou_novel_catalog_repository.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/repositories/novel_catalog_repository.dart';

final novelCatalogRepositoryProvider =
    Provider.family<NovelCatalogRepository, NovelSite>((ref, site) {
      return switch (site) {
        NovelSite.narou => ref.watch(narouNovelCatalogRepositoryProvider),
        NovelSite.narouR18 => ref.watch(narouR18NovelCatalogRepositoryProvider),
        NovelSite.aozora => AozoraNovelCatalogRepository(
          ref.watch(aozoraIndexStoreProvider),
        ),
      };
    });
