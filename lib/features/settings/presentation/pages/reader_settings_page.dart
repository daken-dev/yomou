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

    Future<void> save(ReaderSettings next) async {
      await store.saveSettings(settings.copyWith(reader: next));
    }

    return ListView(
      children: [
        const ListTile(title: Text('文字方向')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
        const Divider(),
        SwitchListTile(
          title: const Text('紙のテクスチャを適用'),
          subtitle: const Text('Paper 03 を使用'),
          value: reader.usePaperTexture,
          onChanged: (value) {
            save(reader.copyWith(usePaperTexture: value));
          },
        ),
        const ListTile(title: Text('紙色')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
        const Divider(),
        ListTile(
          title: Text('文字サイズ ${reader.fontSize.toStringAsFixed(1)}'),
        ),
        Slider(
          min: 14,
          max: 32,
          divisions: 18,
          value: reader.fontSize.clamp(14, 32).toDouble(),
          onChanged: (value) {
            save(reader.copyWith(fontSize: value));
          },
        ),
        ListTile(
          title: Text('余白 ${reader.pageMarginScale.toStringAsFixed(2)}'),
        ),
        Slider(
          min: 0.6,
          max: 1.2,
          divisions: 12,
          value: reader.pageMarginScale.clamp(0.6, 1.2).toDouble(),
          onChanged: (value) {
            save(reader.copyWith(pageMarginScale: value));
          },
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('横画面で見開きモードにする'),
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
      ],
    );
  }
}
