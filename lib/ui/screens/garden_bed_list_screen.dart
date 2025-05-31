import 'dart:async';

import 'package:deferred_state/deferred_state.dart';
import 'package:flutter/material.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/gardenbed_api.dart';
import '../../api/notification_manager.dart';
import '../../util/ansi_color.dart';
import '../../util/exceptions.dart';
import '../dialog/timer_dialog.dart';
import '../widgets/hmb_toast.dart';

class GardenBedListScreen extends StatefulWidget {
  const GardenBedListScreen({super.key});

  @override
  _GardenBedListScreenState createState() => _GardenBedListScreenState();
}

class _GardenBedListScreenState extends DeferredState<GardenBedListScreen> {
  late GardenBedListData listData;
  final api = GardenBedApi(); // Example: your actual API

  final timers = <int, Timer>{};
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
  Future<void> asyncInitState() async {
    listData = await _fetchData();
    _startCountdownTimers();
  }

  @override
  void dispose() {
    print(orange('removing notification listener'));
    NotificationManager().removeListener(noticeListener);
    super.dispose();
  }

  Future<GardenBedListData> _fetchData() async => api.fetchGardenBeds();

  Future<void> _refresh() async {
    listData = await _fetchData();
    _startCountdownTimers();
    setState(() {});
  }

  Future<void> _handleNotice(Notice notice) async {
    print('_handleNotice');
    if (notice.featureType != FeatureType.gardenBed) {
      return;
    }
    switch (notice.noticeType) {
      case NoticeType.start:
        print('Notice: start');
      case NoticeType.stop:
        final timer = timers[notice.featureId];
        if (timer != null) {
          timer.cancel();
        }
        await _refresh();
    }
  }

  /// Start countdown timers for beds with remaining durations
  void _startCountdownTimers() {
    for (final bed in listData.beds) {
      if (bed.remainingDuration > Duration.zero) {
        final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            bed.remainingDuration =
                bed.remainingDuration - const Duration(seconds: 1);
            if (bed.remainingDuration.inSeconds <= 0) {
              bed
                ..remainingDuration = Duration.zero
                ..isOn = false;
              timer.cancel();
              timers.remove(bed.id);
            }
          });
        });
        final old = timers[bed.id!];
        if (old != null) {
          old.cancel();
        }
        timers[bed.id!] = timer;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Garden Beds')),
    body: DeferredBuilder(
      this,
      builder: (context) {
        if (listData.beds.isEmpty) {
          return const Center(child: Text('No garden beds found.'));
        }
        return ListView.builder(
          itemCount: listData.beds.length,
          itemBuilder: (ctx, index) {
            final bed = listData.beds[index];
            return StatefulBuilder(
              builder: (context, setState) => Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(bed.name!),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bed.remainingDuration != Duration.zero)
                        Text(
                          'Remaining: ${_formatDuration(bed.remainingDuration)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Last: ${bed.lastWateringDateTimeString}'),
                          Text('Duration: ${bed.lastWateringDurationString}'),
                        ],
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: bed.isOn,
                    onChanged: (on) async {
                      if (on) {
                        await _onStartWatering(bed);
                        setState(() {});
                      } else {
                        await _stopWatering(bed);
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );

  /// If toggling ON, ask for a duration in minutes
  Future<void> _onStartWatering(GardenBedData bed) async {
    final duration = await _showTimerDialog();
    if (duration == null) {
      // user canceled
      return;
    }
    try {
      await api.startTimer(bed.id!, duration, 'User initiated');
      HMBToast.info('Started watering bed: ${bed.name}');
      await _refresh();
    } on NetworkException catch (e) {
      HMBToast.error('Failed to start watering: $e');
    }
  }

  /// If toggling OFF, stop watering immediately
  Future<void> _stopWatering(GardenBedData bed) async {
    try {
      await api.stopTimer(bed.id!);
      HMBToast.info('Stopped watering bed: ${bed.name}');
      await _refresh();
    } on NetworkException catch (e) {
      HMBToast.error('Failed to stop watering: $e');
    }
  }

  /// Show a dialog for the user to enter watering duration in minutes
  Future<Duration?> _showTimerDialog() async => TimerDialog.show(
    context,
    title: 'Select Watering Time',
    onTimerSelected: (duration) {
      print('Timer selected: ${duration.inMinutes} minutes');
    },
  );

  /// Format a `Duration` into a human-readable string
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
