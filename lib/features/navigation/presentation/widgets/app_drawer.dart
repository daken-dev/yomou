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
              _SiteSection(
                title: 'なろう',
                routePrefix: '/narou/',
                currentLocation: currentLocation,
                children: [
                  _DrawerItem(
                    icon: Icons.trending_up_outlined,
                    selectedIcon: Icons.trending_up,
                    label: 'ランキング',
                    location: '/narou/ranking',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/narou/ranking'),
                  ),
                  _DrawerItem(
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    label: '検索',
                    location: '/narou/search',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/narou/search'),
                  ),
                ],
              ),
              _SiteSection(
                title: 'なろうR18',
                routePrefix: '/narou-r18/',
                currentLocation: currentLocation,
                children: [
                  _DrawerItem(
                    icon: Icons.trending_up_outlined,
                    selectedIcon: Icons.trending_up,
                    label: 'ランキング',
                    location: '/narou-r18/ranking',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/narou-r18/ranking'),
                  ),
                  _DrawerItem(
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    label: '検索',
                    location: '/narou-r18/search',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/narou-r18/search'),
                  ),
                ],
              ),
              _SiteSection(
                title: 'カクヨム',
                routePrefix: '/kakuyomu/',
                currentLocation: currentLocation,
                children: [
                  _DrawerItem(
                    icon: Icons.trending_up_outlined,
                    selectedIcon: Icons.trending_up,
                    label: 'ランキング',
                    location: '/kakuyomu/ranking',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/kakuyomu/ranking'),
                  ),
                  _DrawerItem(
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    label: '検索',
                    location: '/kakuyomu/search',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/kakuyomu/search'),
                  ),
                ],
              ),
              _SiteSection(
                title: 'ノベルアップ+',
                routePrefix: '/novelup/',
                currentLocation: currentLocation,
                children: [
                  _DrawerItem(
                    icon: Icons.trending_up_outlined,
                    selectedIcon: Icons.trending_up,
                    label: 'ランキング',
                    location: '/novelup/ranking',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/novelup/ranking'),
                  ),
                  _DrawerItem(
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    label: '検索',
                    location: '/novelup/search',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/novelup/search'),
                  ),
                ],
              ),
              _SiteSection(
                title: 'ハーメルン',
                routePrefix: '/hameln/',
                currentLocation: currentLocation,
                children: [
                  _DrawerItem(
                    icon: Icons.trending_up_outlined,
                    selectedIcon: Icons.trending_up,
                    label: 'ランキング',
                    location: '/hameln/ranking',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/hameln/ranking'),
                  ),
                  _DrawerItem(
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    label: '検索',
                    location: '/hameln/search',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/hameln/search'),
                  ),
                ],
              ),
              _SiteSection(
                title: '青空文庫',
                routePrefix: '/aozora/',
                currentLocation: currentLocation,
                children: [
                  _DrawerItem(
                    icon: Icons.menu_book_outlined,
                    selectedIcon: Icons.menu_book,
                    label: '検索',
                    location: '/aozora/search',
                    currentLocation: currentLocation,
                    onTap: () => _go(context, '/aozora/search'),
                  ),
                ],
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

class _SiteSection extends StatefulWidget {
  const _SiteSection({
    required this.title,
    required this.routePrefix,
    required this.currentLocation,
    required this.children,
  });

  final String title;
  final String routePrefix;
  final String currentLocation;
  final List<Widget> children;

  @override
  State<_SiteSection> createState() => _SiteSectionState();
}

class _SiteSectionState extends State<_SiteSection> {
  late final ExpansibleController _controller;

  bool get _isActive => widget.currentLocation.startsWith(widget.routePrefix);

  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
    if (_isActive) {
      _controller.expand();
    }
  }

  @override
  void didUpdateWidget(covariant _SiteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isActive || oldWidget.currentLocation == widget.currentLocation) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.expand();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = _isActive;

    return ExpansionTile(
      controller: _controller,
      initiallyExpanded: isActive,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.only(left: 12),
      title: Text(
        widget.title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: widget.children,
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
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String location;
  final String currentLocation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected =
        currentLocation == location ||
        (location != '/' && currentLocation.startsWith(location));
    final theme = Theme.of(context);

    return ListTile(
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
    );
  }
}
