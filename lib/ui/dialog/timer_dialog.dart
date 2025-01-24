import 'dart:async';

import 'package:flutter/material.dart';

class TimerDialog extends StatelessWidget {
  const TimerDialog({
    required this.title,
    required this.onTimerSelected,
    super.key,
  });
  final String title;
  final void Function(Duration) onTimerSelected;

  /// Show the dialog
  static Future<Duration?> show(
    BuildContext context, {
    required String title,
    required void Function(Duration) onTimerSelected,
  }) =>
      showDialog<Duration?>(
        context: context,
        barrierDismissible: false, // Prevent dismissal by tapping outside
        builder: (ctx) =>
            TimerDialog(title: title, onTimerSelected: onTimerSelected),
      );

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Timer Options
              ..._buildTimerButtons(context),

              const SizedBox(height: 16),

              // Cancel Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(), // Close the dialog
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      );

  List<Widget> _buildTimerButtons(BuildContext context) {
    const timerOptions = {
      '10 Seconds': Duration(seconds: 10),
      '15 Minutes': Duration(minutes: 15),
      '20 Minutes': Duration(minutes: 20),
      '30 Minutes': Duration(minutes: 30),
      '45 Minutes': Duration(minutes: 45),
      '1 Hour': Duration(hours: 1),
      '90 Minutes': Duration(minutes: 90),
      '2 Hours': Duration(hours: 2),
    };

    return timerOptions.entries
        .map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(entry.value); // Close the dialog
                },
                child: Text(entry.key),
              ),
            ))
        .toList();
  }
}
