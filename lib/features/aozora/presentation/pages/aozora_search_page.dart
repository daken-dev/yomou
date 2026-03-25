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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // Search text field
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: ListenableBuilder(
                  listenable: _queryController,
                  builder: (context, _) {
                    if (_queryController.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () => _queryController.clear(),
                    );
                  },
                ),
                hintText: '作品名や著者名で検索',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 24),

            // Search target section
            _SectionLabel(label: '検索範囲', colorScheme: colorScheme),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<NovelSearchTarget>(
                segments: [
                  for (final target in NovelSearchTargetX.selectableValues)
                    if (_targets.contains(target))
                      ButtonSegment(
                        value: target,
                        label: Text(
                          target.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                ],
                selected: {_target},
                onSelectionChanged: (selected) {
                  setState(() {
                    _target = selected.first;
                  });
                },
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Index status section
            _SectionLabel(label: 'インデックス', colorScheme: colorScheme),
            const SizedBox(height: 8),
            _IndexStatusCard(
              indexState: indexState,
              onDownload: () => _downloadIndex(manual: true),
            ),

            const SizedBox(height: 32),

            // Search button
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.search_rounded),
              label: const Text('検索する'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
          SnackBar(
            content: const Text('青空文庫インデックスを更新しました。'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('インデックス更新に失敗しました: $error'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();

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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _IndexStatusCard extends StatelessWidget {
  const _IndexStatusCard({
    required this.indexState,
    required this.onDownload,
  });

  final AsyncValue<AozoraIndexControllerState> indexState;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: indexState.when(
          data: (state) {
            final hasIndex = state.status.hasIndex;
            return Row(
              children: [
                Icon(
                  hasIndex
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 20,
                  color: hasIndex ? colorScheme.primary : colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasIndex
                            ? '${state.status.totalWorks}件の作品'
                            : 'インデックス未取得',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasIndex && state.status.fetchedAt != null)
                        Text(
                          _formatDateTime(state.status.fetchedAt!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: Text(hasIndex ? '更新' : '取得'),
                ),
              ],
            );
          },
          error: (error, _) => Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '状態取得に失敗しました',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('再試行'),
              ),
            ],
          ),
          loading: () => Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'インデックス確認中...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $hh:$mm 更新';
  }
}
