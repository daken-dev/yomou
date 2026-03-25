import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_drawer.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (context.canPop()) {
                    context.pop();
                  }
                },
              )
            : null,
        title: Text(title),
        actions: actions,
      ),
      drawer: canPop ? null : const AppDrawer(),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
