import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(title: const Text('HOME'), onTap: () => _go(context, '/')),
          ExpansionTile(
            title: const Text('なろう'),
            children: [
              ListTile(
                title: const Text('ランキング'),
                onTap: () => _go(context, '/narou/ranking'),
              ),
              ListTile(
                title: const Text('検索'),
                onTap: () => _go(context, '/narou/search'),
              ),
            ],
          ),
          const ListTile(title: Text('他のサイト (予定)')),
          ListTile(
            title: const Text('設定'),
            onTap: () => _go(context, '/settings'),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, String location) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go(location);
  }
}
