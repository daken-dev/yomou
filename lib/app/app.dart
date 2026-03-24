import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomou/app/router/app_router.dart';

class YomouApp extends ConsumerWidget {
  const YomouApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'yomou',
      routerConfig: ref.watch(appRouterProvider),
      theme: ThemeData(),
    );
  }
}
