import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'drawer_item.dart';

class MyDrawer extends StatelessWidget {
  MyDrawer({super.key});

  /// Here’s a revised structure reflecting the Java app’s menu:
  final List<DrawerItem> drawerItems = [
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
            title: 'GardenBed Configuration', route: '/config/gardenbeds'),
        DrawerItem(title: 'User Admin', route: '/config/users'),
      ],
    ),
    // If you have additional menu entries from your Java code, add them here.
  ];

  @override
  Widget build(BuildContext context) => Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: drawerItems
                .map((item) => _buildDrawerItem(item, context))
                .toList(),
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
