import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yomou/features/navigation/presentation/widgets/app_drawer.dart';

const _desktopNavigationBreakpoint = 1100.0;
const _desktopNavigationWidth = 280.0;

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
    final isDesktopShell = _DesktopNavigationShellScope.maybeOf(context);
    final isDesktopLayout =
        !isDesktopShell &&
        !canPop &&
        MediaQuery.sizeOf(context).width >= _desktopNavigationBreakpoint;
    final bodyContent = isDesktopShell
        ? SafeArea(top: false, child: _ConstrainedBody(child: body))
        : SafeArea(
            child: isDesktopLayout
                ? Row(
                    children: [
                      SizedBox(
                        width: _desktopNavigationWidth,
                        child: Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
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
      drawer: canPop || isDesktopLayout || isDesktopShell
          ? null
          : const AppDrawer(),
      body: bodyContent,
      floatingActionButton: floatingActionButton,
    );
  }
}

class DesktopNavigationShell extends StatelessWidget {
  const DesktopNavigationShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < _desktopNavigationBreakpoint) {
      return child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    return _DesktopNavigationShellScope(
      child: Row(
        children: [
          SizedBox(
            width: _desktopNavigationWidth,
            child: Material(
              color: colorScheme.surfaceContainerLow,
              child: const SafeArea(child: AppNavigationPane()),
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DesktopNavigationShellScope extends InheritedWidget {
  const _DesktopNavigationShellScope({required super.child});

  static bool maybeOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<
              _DesktopNavigationShellScope
            >() !=
        null;
  }

  @override
  bool updateShouldNotify(_DesktopNavigationShellScope oldWidget) => false;
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
