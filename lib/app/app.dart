import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/app/router/app_router.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';
import 'package:yomou/features/settings/application/settings_providers.dart';
import 'package:yomou/features/settings/domain/entities/app_settings.dart';

class YomouApp extends ConsumerWidget {
  const YomouApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(downloadSchedulerBootstrapProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = switch (settingsAsync) {
      AsyncData(:final value) => value,
      _ => const AppSettings.defaults(),
    };

    return MaterialApp.router(
      title: 'yomou',
      routerConfig: ref.watch(appRouterProvider),
      themeMode: settings.themeMode.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B7AA6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B7AA6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}
