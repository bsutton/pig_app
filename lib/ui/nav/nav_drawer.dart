import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../util/auth_store.dart';
import 'drawer_item.dart';

class MyDrawer extends StatelessWidget {
  MyDrawer({super.key});

  final drawerItems = <DrawerItem>[
    DrawerItem(title: 'Overview', route: '/overview'),
    DrawerItem(title: 'Garden Beds', route: '/garden_beds'),
    DrawerItem(title: 'Lighting', route: '/lighting'),
    DrawerItem(title: 'Schedule', route: '/schedule'),
    DrawerItem(title: 'History', route: '/history'),
    DrawerItem(
      title: 'Configuration',
      route: '',
      children: [
        DrawerItem(title: 'EndPoint Configuration', route: '/config/endpoints'),
        DrawerItem(
          title: 'Valve Pin Mapping',
          route: '/config/valve_pin_mapping',
        ),
        DrawerItem(
          title: 'GardenBed Configuration',
          route: '/config/gardenbeds',
        ),
        DrawerItem(title: 'Admin', route: '/config/users'),
      ],
    ),
    // If you have additional menu entries from your Java code, add them here.
  ];

  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: drawerItems
                  .map((item) => _buildDrawerItem(item, context))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await AuthStore.clear();
              if (context.mounted) {
                context.go('/public/login');
              }
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildDrawerItem(DrawerItem item, BuildContext context) {
    if (item.children != null && item.children!.isNotEmpty) {
      return ExpansionTile(
        title: Text(item.title),
        children: item.children!
            .map((child) => _buildDrawerItem(child, context))
            .toList(),
      );
    } else {
      return ListTile(
        title: Text(item.title),
        onTap: item.route.isNotEmpty
            ? () {
                Navigator.pop(context); // Close the drawer
                context.go(item.route);
              }
            : null, // If no route, disable tapping
      );
    }
  }
}
