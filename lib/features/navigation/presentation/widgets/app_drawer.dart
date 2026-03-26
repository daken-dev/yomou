import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(child: AppNavigationPane(closeOnNavigate: true));
  }
}

class AppNavigationPane extends StatelessWidget {
  const AppNavigationPane({super.key, this.closeOnNavigate = false});

  final bool closeOnNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Column(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'よもう',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _DrawerItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'ホーム',
                location: '/',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/'),
              ),
              const _SectionHeader(title: 'なろう'),
              _DrawerItem(
                icon: Icons.trending_up_outlined,
                selectedIcon: Icons.trending_up,
                label: 'ランキング',
                location: '/narou/ranking',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/narou/ranking'),
                indent: true,
              ),
              _DrawerItem(
                icon: Icons.search_outlined,
                selectedIcon: Icons.search,
                label: '検索',
                location: '/narou/search',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/narou/search'),
                indent: true,
              ),
              const _SectionHeader(title: 'なろうR18'),
              _DrawerItem(
                icon: Icons.trending_up_outlined,
                selectedIcon: Icons.trending_up,
                label: 'ランキング',
                location: '/narou-r18/ranking',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/narou-r18/ranking'),
                indent: true,
              ),
              _DrawerItem(
                icon: Icons.search_outlined,
                selectedIcon: Icons.search,
                label: '検索',
                location: '/narou-r18/search',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/narou-r18/search'),
                indent: true,
              ),
              const _SectionHeader(title: 'カクヨム'),
              _DrawerItem(
                icon: Icons.trending_up_outlined,
                selectedIcon: Icons.trending_up,
                label: 'ランキング',
                location: '/kakuyomu/ranking',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/kakuyomu/ranking'),
                indent: true,
              ),
              _DrawerItem(
                icon: Icons.search_outlined,
                selectedIcon: Icons.search,
                label: '検索',
                location: '/kakuyomu/search',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/kakuyomu/search'),
                indent: true,
              ),
              const _SectionHeader(title: '青空文庫'),
              _DrawerItem(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book,
                label: '検索',
                location: '/aozora/search',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/aozora/search'),
                indent: true,
              ),
              const Divider(height: 1),
              _DrawerItem(
                icon: Icons.download_outlined,
                selectedIcon: Icons.download,
                label: 'ダウンロード状況',
                location: '/downloads',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/downloads'),
              ),
              _DrawerItem(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: '設定',
                location: '/settings',
                currentLocation: currentLocation,
                onTap: () => _go(context, '/settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _go(BuildContext context, String location) {
    final router = GoRouter.of(context);
    if (closeOnNavigate) {
      Navigator.of(context).pop();
    }
    router.go(location);
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
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.location,
    required this.currentLocation,
    required this.onTap,
    this.indent = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String location;
  final String currentLocation;
  final VoidCallback onTap;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    final isSelected =
        currentLocation == location ||
        (location != '/' && currentLocation.startsWith(location));
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(left: indent ? 12 : 0),
      child: ListTile(
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.3,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
