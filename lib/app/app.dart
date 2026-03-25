import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/app/router/app_router.dart';
import 'package:yomou/features/downloads/application/download_providers.dart';

class YomouApp extends ConsumerWidget {
  const YomouApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(downloadSchedulerBootstrapProvider);

    return MaterialApp.router(
      title: 'yomou',
      routerConfig: ref.watch(appRouterProvider),
      theme: ThemeData(),
    );
  }
}
