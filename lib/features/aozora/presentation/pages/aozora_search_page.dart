import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/aozora/application/aozora_index_controller.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_order.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_request.dart';
import 'package:yomou/features/novels/domain/entities/novel_search_target.dart';
import 'package:yomou/features/novels/domain/entities/novel_site.dart';

class AozoraSearchPage extends ConsumerStatefulWidget {
  const AozoraSearchPage({super.key});

  @override
  ConsumerState<AozoraSearchPage> createState() => _AozoraSearchPageState();
}

class _AozoraSearchPageState extends ConsumerState<AozoraSearchPage> {
  late final TextEditingController _queryController;
  NovelSearchTarget _target = NovelSearchTarget.all;
  var _didCheckIndex = false;

  static const _targets = <NovelSearchTarget>{
    NovelSearchTarget.all,
    NovelSearchTarget.title,
    NovelSearchTarget.author,
  };

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indexState = ref.watch(aozoraIndexControllerProvider);

    final current = indexState.value;
    if (!_didCheckIndex && current != null && !current.status.hasIndex) {
      _didCheckIndex = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showInitialDownloadDialog(context);
      });
    }

    return AppScaffold(
      title: '青空文庫検索',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _queryController,
            decoration: const InputDecoration(
              labelText: '作品名や著者名で検索',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          SegmentedButton<NovelSearchTarget>(
            segments: [
              for (final target in NovelSearchTargetX.selectableValues)
                if (_targets.contains(target))
                  ButtonSegment(value: target, label: Text(target.label)),
            ],
            selected: {_target},
            onSelectionChanged: (selected) {
              setState(() {
                _target = selected.first;
              });
            },
            showSelectedIcon: false,
          ),
          const SizedBox(height: 16),
          indexState.when(
            data: (state) => Text(
              state.status.hasIndex
                  ? 'インデックス: ${state.status.totalWorks}件（${_formatDateTime(state.status.fetchedAt!)}）'
                  : 'インデックス未取得',
            ),
            error: (error, _) => Text('インデックス状態取得失敗: $error'),
            loading: () => const Text('インデックス確認中...'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _downloadIndex(manual: true),
            icon: const Icon(Icons.download),
            label: const Text('一覧をダウンロード/更新'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.search),
            label: const Text('検索する'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInitialDownloadDialog(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('青空文庫一覧を取得しますか？'),
          content: const Text(
            '初回検索には作品一覧CSVの取得が必要です。\nダウンロードしてローカル検索を有効化します。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('あとで'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ダウンロード'),
            ),
          ],
        );
      },
    );
    if (accepted == true && mounted) {
      await _downloadIndex(manual: false);
    }
  }

  Future<void> _downloadIndex({required bool manual}) async {
    try {
      await ref.read(aozoraIndexControllerProvider.notifier).downloadOrUpdate();
      if (!mounted) {
        return;
      }
      if (manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('青空文庫インデックスを更新しました。')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('インデックス更新に失敗しました: $error')),
      );
    }
  }

  void _submit() {
    final request = NovelSearchRequest(
      site: NovelSite.aozora,
      query: _queryController.text,
      target: _target,
      order: NovelSearchOrder.newest,
    );

    final location = Uri(
      path: '/aozora/search/results',
      queryParameters: request.toQueryParameters(),
    ).toString();
    context.push(location);
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $hh:$mm';
  }
}
