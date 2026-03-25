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
    final theme = Theme.of(context);

    return ListView(
      children: [
        _SectionHeader(title: '外観'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        const SizedBox(height: 8),
        _SectionHeader(title: '動作'),
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
        const SizedBox(height: 8),
        _SectionHeader(title: 'リーダー'),
        ListTile(
          title: const Text('リーダー設定'),
          subtitle: const Text('文字・紙面・前書き/あとがき'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/reader'),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.tonalIcon(
            onPressed: () => _confirmReset(context, store),
            icon: const Icon(Icons.settings_backup_restore),
            label: const Text('すべての設定を規定値に戻す'),
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
        title: const Text('設定を規定値に戻す'),
        content: const Text('すべての設定が初期状態にリセットされます。この操作は元に戻せません。'),
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
      await store.saveSettings(const AppSettings.defaults());
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
