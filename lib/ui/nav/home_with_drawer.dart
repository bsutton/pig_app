import 'package:flutter/material.dart';
import 'package:june/june.dart';

import '../../util/app_title.dart';
import '../widgets/pig_status_bar.dart';
import 'nav_drawer.dart';

class HomeWithDrawer extends StatelessWidget {
  final Widget initialScreen;
  final bool showDrawer;

  const HomeWithDrawer({
    required this.initialScreen,
    this.showDrawer = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.purple,
      title: JuneBuilder(HMBTitle.new, builder: (title) => Text(title.title)),
      leading: showDrawer
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
    ),
    drawer: showDrawer ? MyDrawer() : null,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PIGStatusBar(),
        Flexible(child: initialScreen),
      ],
    ),
  );
}
