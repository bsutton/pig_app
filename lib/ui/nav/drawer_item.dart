class DrawerItem {
  final String title;

  final String route;

  final List<DrawerItem>? children;

  DrawerItem({required this.title, required this.route, this.children});
}
