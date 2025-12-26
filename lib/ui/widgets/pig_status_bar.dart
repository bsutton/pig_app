import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:go_router/go_router.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/gardenbed_api.dart';
import '../../api/notification_manager.dart';
import '../../util/ansi_color.dart';

class PIGStatusBar extends StatefulWidget {
  const PIGStatusBar({super.key});

  @override
  State<PIGStatusBar> createState() => _PIGStatusBarState();
}

class _PIGStatusBarState extends State<PIGStatusBar> {
  late final NoticeListener noticeListener;

  @override
  void initState() {
    super.initState();
    print(orange('starting notification listener'));
    noticeListener = NotificationManager().addListener((notice) async {
      print('recieved notice $notice');
      await _handleNotice(notice);
    });
  }

  @override
  void dispose() {
    print(orange('removing notification listener'));
    NotificationManager().removeListener(noticeListener);
    super.dispose();
  }

  var running = <int, Notice>{};

  Future<void> _handleNotice(Notice notice) async {
    print('_handleNotice');
    if (notice.featureType != FeatureType.gardenBed) {
      return;
    }
    switch (notice.noticeType) {
      case NoticeType.start:
        running[notice.featureId] = notice;
      case NoticeType.stop:
        running.remove(notice.featureId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.purpleAccent,
    child: Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: FutureBuilderEx(
            // ignore: discarded_futures
            future: GardenBedApi().fetchGardenBeds(),
            errorBuilder: (context, error) => Row(
              children: [
                Expanded(
                  child: Text(
                    'Network error: $error',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  tooltip: 'Reload',
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => _reloadCurrentRoute(context),
                ),
              ],
            ),
            builder: (context, bedList) => Text(
              running.isEmpty
                  ? ''
                  : 'Running: ${running.entries.first.value.description}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );

  void _reloadCurrentRoute(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    if (location.isEmpty) {
      return;
    }
    router.go(location);
  }
}
