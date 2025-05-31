import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/lighting_api.dart';
import '../../api/notification_manager.dart';
import '../../util/ansi_color.dart';

class HMBStatusBar extends StatefulWidget {
  const HMBStatusBar({super.key});

  @override
  State<HMBStatusBar> createState() => _HMBStatusBarState();
}

class _HMBStatusBarState extends State<HMBStatusBar> {
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
            future: LightingApi().fetchLightingList(),
            builder: (context, lightingList) => Text(
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
}
