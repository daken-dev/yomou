import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/aozora/application/aozora_novel_detail_controller.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/downloads/domain/entities/saved_novel_overview.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';
import 'package:yomou/features/novels/domain/entities/novel_summary.dart';

enum _AozoraMenuAction { saveToggle, refresh }

class AozoraNovelDetailPage extends ConsumerWidget {
  const AozoraNovelDetailPage({super.key, required this.novelId});

  final String novelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(aozoraNovelDetailProvider(novelId));
    final savedNovel = ref
        .watch(
          savedNovelOverviewProvider((
            site: NovelSite.aozora,
            novelId: novelId,
          )),
        )
        .value;

    return AppScaffold(
      title: '青空文庫作品',
      actions: [
        PopupMenuButton<_AozoraMenuAction>(
          itemBuilder: (context) => _menuItems(savedNovel),
          onSelected: (action) =>
              _onAction(context, ref, action, detail.value, savedNovel),
        ),
      ],
      floatingActionButton: detail.whenOrNull(
        data: (data) => FloatingActionButton.extended(
          onPressed: () =>
              context.push(_readLocation(data, savedNovel: savedNovel)),
          icon: const Icon(Icons.auto_stories),
          label: Text(
            savedNovel?.hasResumePageProgress == true
                ? '続きを読む ${savedNovel!.resumePageNumber}/${savedNovel.resumePageCount}'
                : '読む',
          ),
        ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('取得に失敗しました: $error')),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                data.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if ((data.subtitle ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  data.subtitle!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 12),
              Text('著者: ${data.author}'),
              if ((data.role ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('役割: ${data.role}'),
              ],
              const SizedBox(height: 16),
              _MetadataSection(data: data),
              if (data.cardUrl != null) ...[
                const SizedBox(height: 8),
                SelectableText('図書カード: ${data.cardUrl}'),
              ],
              if ((data.htmlUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText('HTML: ${data.htmlUrl}'),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    context.push(_readLocation(data, savedNovel: savedNovel)),
                icon: const Icon(Icons.menu_book),
                label: const Text('本文を読む'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<PopupMenuEntry<_AozoraMenuAction>> _menuItems(
    SavedNovelOverview? savedNovel,
  ) {
    return [
      if (savedNovel != null)
        const PopupMenuItem(
          value: _AozoraMenuAction.refresh,
          child: Text('更新を確認'),
        ),
      PopupMenuItem(
        value: _AozoraMenuAction.saveToggle,
        child: Text(savedNovel == null ? '保存する' : '保存を解除'),
      ),
    ];
  }

  void _onAction(
    BuildContext context,
    WidgetRef ref,
    _AozoraMenuAction action,
    AozoraNovelDetailData? detail,
    SavedNovelOverview? savedNovel,
  ) {
    final scheduler = ref.read(downloadSchedulerProvider);

    switch (action) {
      case _AozoraMenuAction.refresh:
        if (savedNovel != null) {
          scheduler.refreshNovel(savedNovel.site, savedNovel.id);
        }
        break;
      case _AozoraMenuAction.saveToggle:
        if (savedNovel != null) {
          scheduler.removeNovel(savedNovel.site, savedNovel.id);
          return;
        }
        if (detail == null) {
          return;
        }
        scheduler.saveNovel(
          NovelSummary(
            site: NovelSite.aozora,
            id: detail.novelId,
            title: detail.title,
            author: detail.author,
            story: detail.subtitle ?? '',
            genre: '青空文庫',
            episodeCount: 1,
            isComplete: true,
            isShortStory: true,
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('保存しました。本文を同期します。')));
        }
        break;
    }
  }

  String _readLocation(
    AozoraNovelDetailData detail, {
    required SavedNovelOverview? savedNovel,
  }) {
    final queryParameters = <String, String>{
      'zip': detail.textZipUrl,
      'title': detail.title,
      'author': detail.author,
    };
    if (savedNovel != null && savedNovel.hasResumePageProgress) {
      queryParameters['resumePage'] = savedNovel.resumePageNumber.toString();
      queryParameters['resumePageCount'] = savedNovel.resumePageCount
          .toString();
    }

    return Uri(
      path: '/aozora/novel/${detail.novelId}/read',
      queryParameters: queryParameters,
    ).toString();
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.data});

  final AozoraNovelDetailData data;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String? value})>[
      (label: '作品名読み', value: data.titleReading),
      (label: '副題読み', value: data.subtitleReading),
      (label: '原題', value: data.originalTitle),
      (label: '初出', value: data.firstAppearance),
      (label: '分類番号', value: data.classification),
      (label: '文字遣い種別', value: data.writingStyle),
      (label: '作品著作権', value: data.workCopyright),
      (label: '公開日', value: data.publicationDate),
      (label: 'CSV最終更新日', value: data.csvUpdatedDate),
      (label: '生年月日', value: data.birthDate),
      (label: '没年月日', value: data.deathDate),
      (label: '人物著作権', value: data.personCopyright),
      (label: '入力者', value: data.inputter),
      (label: '校正者', value: data.proofreader),
      (label: 'テキスト符号化方式', value: data.textEncoding),
      (label: 'HTML符号化方式', value: data.htmlEncoding),
    ];

    final visibleRows = rows
        .where((row) => (row.value ?? '').isNotEmpty)
        .toList();
    if (visibleRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作品情報', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final row in visibleRows) ...[
              SelectableText('${row.label}: ${row.value}'),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}
