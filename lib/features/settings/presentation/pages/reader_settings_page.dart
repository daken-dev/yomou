import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/settings/application/settings_providers.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class ReaderSettingsPage extends ConsumerWidget {
  const ReaderSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return AppScaffold(
      title: 'リーダー設定',
      body: settingsAsync.when(
        data: (settings) => _ReaderSettingsContent(settings: settings),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ReaderSettingsContent extends ConsumerWidget {
  const _ReaderSettingsContent({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(settingsStoreProvider);
    final reader = settings.reader;
    final theme = Theme.of(context);

    Future<void> save(ReaderSettings next) async {
      await store.saveSettings(settings.copyWith(reader: next));
    }

    return ListView(
      children: [
        // ── 文字 ──
        _SectionHeader(title: '文字'),
        _SegmentedTile<ReaderWritingMode>(
          label: '組方向',
          segments: ReaderWritingMode.values,
          selected: reader.writingMode,
          segmentLabel: (v) => v.label,
          onChanged: (v) => save(reader.copyWith(writingMode: v)),
        ),
        _SegmentedTile<ReaderTapPattern>(
          label: 'タップ領域',
          segments: ReaderTapPattern.values,
          selected: reader.tapPattern,
          segmentLabel: (v) => v.label,
          onChanged: (v) => save(reader.copyWith(tapPattern: v)),
        ),
        const SizedBox(height: 8),
        _SliderTile(
          label: '文字サイズ',
          value: reader.fontSize.clamp(14, 32).toDouble(),
          displayValue: reader.fontSize.toStringAsFixed(0),
          min: 14,
          max: 32,
          divisions: 18,
          onChanged: (value) => save(reader.copyWith(fontSize: value)),
          onReset: reader.fontSize == const ReaderSettings.defaults().fontSize
              ? null
              : () => save(reader.copyWith(
                    fontSize: const ReaderSettings.defaults().fontSize,
                  )),
        ),
        // ── 余白 ──
        const SizedBox(height: 8),
        _SectionHeader(title: '余白'),
        _SliderTile(
          label: '上',
          value: reader.paddingTop.clamp(0, 60).toDouble(),
          displayValue: '${reader.paddingTop.round()}',
          min: 0,
          max: 60,
          divisions: 12,
          onChanged: (value) => save(reader.copyWith(paddingTop: value)),
          onReset: reader.paddingTop ==
                  const ReaderSettings.defaults().paddingTop
              ? null
              : () => save(reader.copyWith(
                    paddingTop: const ReaderSettings.defaults().paddingTop,
                  )),
        ),
        _SliderTile(
          label: '下',
          value: reader.paddingBottom.clamp(0, 60).toDouble(),
          displayValue: '${reader.paddingBottom.round()}',
          min: 0,
          max: 60,
          divisions: 12,
          onChanged: (value) => save(reader.copyWith(paddingBottom: value)),
          onReset: reader.paddingBottom ==
                  const ReaderSettings.defaults().paddingBottom
              ? null
              : () => save(reader.copyWith(
                    paddingBottom:
                        const ReaderSettings.defaults().paddingBottom,
                  )),
        ),
        _SliderTile(
          label: '左',
          value: reader.paddingLeft.clamp(0, 60).toDouble(),
          displayValue: '${reader.paddingLeft.round()}',
          min: 0,
          max: 60,
          divisions: 12,
          onChanged: (value) => save(reader.copyWith(paddingLeft: value)),
          onReset: reader.paddingLeft ==
                  const ReaderSettings.defaults().paddingLeft
              ? null
              : () => save(reader.copyWith(
                    paddingLeft: const ReaderSettings.defaults().paddingLeft,
                  )),
        ),
        _SliderTile(
          label: '右',
          value: reader.paddingRight.clamp(0, 60).toDouble(),
          displayValue: '${reader.paddingRight.round()}',
          min: 0,
          max: 60,
          divisions: 12,
          onChanged: (value) => save(reader.copyWith(paddingRight: value)),
          onReset: reader.paddingRight ==
                  const ReaderSettings.defaults().paddingRight
              ? null
              : () => save(reader.copyWith(
                    paddingRight: const ReaderSettings.defaults().paddingRight,
                  )),
        ),
        SwitchListTile(
          title: const Text('インカメラ回避'),
          subtitle: const Text('上部の余白にノッチ分を加算する'),
          value: reader.avoidNotch,
          onChanged: (value) {
            save(reader.copyWith(avoidNotch: value));
          },
        ),

        // ── 紙面 ──
        const SizedBox(height: 8),
        _SectionHeader(title: '紙面'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SegmentedButton<ReaderPaperColorPreset>(
            segments: ReaderPaperColorPreset.values
                .map(
                  (preset) => ButtonSegment<ReaderPaperColorPreset>(
                    value: preset,
                    label: Text(preset.label),
                  ),
                )
                .toList(growable: false),
            selected: {reader.paperColorPreset},
            onSelectionChanged: (value) {
              save(reader.copyWith(paperColorPreset: value.first));
            },
          ),
        ),
        SwitchListTile(
          title: const Text('紙のテクスチャ'),
          subtitle: const Text('紙の質感を再現する'),
          value: reader.usePaperTexture,
          onChanged: (value) {
            save(reader.copyWith(usePaperTexture: value));
          },
        ),

        // ── 表示 ──
        const SizedBox(height: 8),
        _SectionHeader(title: '表示'),
        SwitchListTile(
          title: const Text('横画面で見開き'),
          subtitle: const Text('横向き時に2ページ並べて表示'),
          value: reader.enableLandscapeDoublePage,
          onChanged: (value) {
            save(reader.copyWith(enableLandscapeDoublePage: value));
          },
        ),
        _SegmentedTile<ReaderSinglePagePosition>(
          label: '単ページ表示位置',
          segments: ReaderSinglePagePosition.values,
          selected: reader.singlePagePosition,
          segmentLabel: (v) => v.label,
          onChanged: (v) => save(reader.copyWith(singlePagePosition: v)),
        ),
        SwitchListTile(
          title: const Text('前書きを表示'),
          value: reader.showPreface,
          onChanged: (value) {
            save(reader.copyWith(showPreface: value));
          },
        ),
        SwitchListTile(
          title: const Text('あとがきを表示'),
          value: reader.showAfterword,
          onChanged: (value) {
            save(reader.copyWith(showAfterword: value));
          },
        ),

        // ── リセット ──
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.tonalIcon(
            onPressed: () => _confirmReset(context, store),
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('リーダー設定を規定値に戻す'),
            style: FilledButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, dynamic store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リーダー設定を規定値に戻す'),
        content: const Text('リーダーの設定が初期状態にリセットされます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await store.saveSettings(
        settings.copyWith(reader: const ReaderSettings.defaults()),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SegmentedTile<T extends Enum> extends StatelessWidget {
  const _SegmentedTile({
    super.key,
    required this.label,
    required this.segments,
    required this.selected,
    required this.segmentLabel,
    required this.onChanged,
  });

  final String label;
  final List<T> segments;
  final T selected;
  final String Function(T) segmentLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SegmentedButton<T>(
          segments: segments
              .map(
                (v) => ButtonSegment<T>(value: v, label: Text(segmentLabel(v))),
              )
              .toList(growable: false),
          selected: {selected},
          onSelectionChanged: (value) => onChanged(value.first),
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.onReset,
  });

  final String label;
  final double value;
  final String displayValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            displayValue,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onReset != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                icon: const Icon(Icons.restart_alt, size: 20),
                tooltip: '規定値に戻す',
                visualDensity: VisualDensity.compact,
                onPressed: onReset,
              ),
            ),
        ],
      ),
      subtitle: Slider(
        min: min,
        max: max,
        divisions: divisions,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
