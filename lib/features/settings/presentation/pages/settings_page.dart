import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_scaffold.dart';
import 'package:yomou/features/settings/application/settings_providers.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return AppScaffold(
      title: '設定',
      body: settingsAsync.when(
        data: (settings) => _SettingsContent(settings: settings),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  const _SettingsContent({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(settingsStoreProvider);

    return ListView(
      children: [
        const ListTile(title: Text('アプリテーマ')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<AppThemeMode>(
            segments: AppThemeMode.values
                .map(
                  (mode) => ButtonSegment<AppThemeMode>(
                    value: mode,
                    label: Text(mode.label),
                  ),
                )
                .toList(growable: false),
            selected: {settings.themeMode},
            onSelectionChanged: (value) {
              store.saveSettings(settings.copyWith(themeMode: value.first));
            },
          ),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('HOMEから直接リーダーへ'),
          subtitle: const Text('作品詳細をスキップして続きから開く'),
          value: settings.openHomeNovelDirectlyInReader,
          onChanged: (value) {
            store.saveSettings(
              settings.copyWith(openHomeNovelDirectlyInReader: value),
            );
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('リーダー設定'),
          subtitle: const Text('文字・紙面・前書き/あとがき'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/reader'),
        ),
      ],
    );
  }
}
