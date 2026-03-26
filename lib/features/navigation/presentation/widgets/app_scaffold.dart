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
    final isDesktopLayout = !canPop && MediaQuery.sizeOf(context).width >= 1100;
    final bodyContent = SafeArea(
      child: isDesktopLayout
          ? Row(
              children: [
                SizedBox(
                  width: 280,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: const AppNavigationPane(),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
                Expanded(child: _ConstrainedBody(child: body)),
              ],
            )
          : _ConstrainedBody(child: body),
    );
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
      drawer: canPop || isDesktopLayout ? null : const AppDrawer(),
      body: bodyContent,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _ConstrainedBody extends StatelessWidget {
  const _ConstrainedBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: child,
      ),
    );
  }
}
