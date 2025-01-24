import 'dart:async';

import 'package:deferred_state/deferred_state.dart';
import 'package:flutter/material.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/gardenbed_api.dart';

/// Hypothetical API class to fetch and modify garden bed states.
import '../../util/exceptions.dart';
import '../dialog/timer_dialog.dart';
import '../widgets/hmb_toast.dart';

/// The screen that displays a list of garden beds with on/off toggles,
/// last-watered info, and durations.
class GardenBedListScreen extends StatefulWidget {
  const GardenBedListScreen({super.key});

  @override
  _GardenBedListScreenState createState() => _GardenBedListScreenState();
}

class _GardenBedListScreenState extends DeferredState<GardenBedListScreen> {
  late GardenBedListData listData;
  final api = GardenBedApi(); // Example: your actual API

  @override
  Future<void> asyncInitState() async {
    listData = await _fetchData();
  }

  Future<GardenBedListData> _fetchData() async => api.fetchGardenBeds();

  Future<void> _refresh() async {
    listData = await _fetchData();
    setState(() {});
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
                            subtitle: Row(
                              children: [
                                // Last Watered
                                Text('Last: ${bed.lastWateringDateTimeString}'),
                                const SizedBox(width: 16),
                                // Duration
                                Text(
                                    'Duration: ${bed.lastWateringDurationString}'),
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
                        ));
              });
        },
      ));

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
          // Perform actions with the selected timer
        },
      );
}
