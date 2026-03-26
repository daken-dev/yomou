import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final router = ref.watch(appRouterProvider);
    final settings = switch (settingsAsync) {
      AsyncData(:final value) => value,
      _ => const AppSettings.defaults(),
    };

    return MaterialApp.router(
      title: 'よもう',
      routerConfig: router,
      builder: (context, child) => _BackMouseDetector(
        router: router,
        child: child ?? const SizedBox.shrink(),
      ),
      themeMode: settings.themeMode.themeMode,
      debugShowCheckedModeBanner: false,
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

class _BackMouseDetector extends StatelessWidget {
  const _BackMouseDetector({required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!_supportsDesktopPointerNavigation) {
      return child;
    }

    return Listener(
      onPointerDown: (event) {
        if ((event.buttons & kBackMouseButton) == 0) {
          return;
        }
        FocusManager.instance.primaryFocus?.unfocus();
        if (router.canPop()) {
          router.pop();
        }
      },
      child: child,
    );
  }
}

final _supportsDesktopPointerNavigation =
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows);
