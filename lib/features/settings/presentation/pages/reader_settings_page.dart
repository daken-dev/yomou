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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SegmentedButton<ReaderWritingMode>(
            segments: ReaderWritingMode.values
                .map(
                  (mode) => ButtonSegment<ReaderWritingMode>(
                    value: mode,
                    label: Text(mode.label),
                  ),
                )
                .toList(growable: false),
            selected: {reader.writingMode},
            onSelectionChanged: (value) {
              save(reader.copyWith(writingMode: value.first));
            },
          ),
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
        ),
        _SliderTile(
          label: '余白',
          value: reader.pageMarginScale.clamp(0.6, 1.2).toDouble(),
          displayValue: '${(reader.pageMarginScale * 100).round()}%',
          min: 0.6,
          max: 1.2,
          divisions: 12,
          onChanged: (value) => save(reader.copyWith(pageMarginScale: value)),
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

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String displayValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

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
