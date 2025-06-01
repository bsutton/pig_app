import 'package:flutter/material.dart';
import 'package:june/june.dart';

import '../../util/app_title.dart';
import '../widgets/pig_status_bar.dart';
import 'nav_drawer.dart';

class HomeWithDrawer extends StatelessWidget {
  const HomeWithDrawer({required this.initialScreen, super.key});
  final Widget initialScreen;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.purple,
      title: JuneBuilder(HMBTitle.new, builder: (title) => Text(title.title)),
    ),
    drawer: MyDrawer(),
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PIGStatusBar(),
        Flexible(child: initialScreen),
      ],
    ),
  );
}
