// lib/src/ui/history/history_screen.dart

import 'package:deferred_state/deferred_state.dart';
import 'package:flutter/material.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/history_api.dart';

/// A screen that shows a scrolling list of past “history” events (e.g. watering cycles).
///
/// Uses the same pattern as OverviewScreen:
///  1. In asyncInitState, fetch history from the API.
///  2. In build(), wrap with DeferredBuilder to wait until the fetch completes.
///  3. Once data is available, show a ListView of rows.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends DeferredState<HistoryScreen> {
  /// This will hold the list of History entries once fetched.
  late List<HistoryData>? _historyList;

  final api = HistoryApi();

  @override
  Future<void> asyncInitState() async {
    // Fetch the list of History entries from the server.
    // If you have a wrapper class (e.g. HistoryData) replace this with your own call.
    _historyList = await api.fetchHistory();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('History')),
    body: DeferredBuilder(
      this,
      builder: (context) {
        // If the API returned null or an empty list, show a “No data” message
        if (_historyList == null || _historyList!.isEmpty) {
          return const Center(child: Text('No history available.'));
        }

        // Otherwise, build the scrollable list of history rows.
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _historyList!.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = _historyList![index];
            return _buildHistoryRow(entry);
          },
        );
      },
    ),
  );

  /// Each row shows:
  ///   1. The event start time (formatted)
  ///   2. The event duration (if present; otherwise “In Progress”)
  ///   3. The garden-feature ID (you can replace this with a name if you have it).
  Widget _buildHistoryRow(HistoryData entry) {
    final startString = _formatDate(entry.eventStart);

    // If the eventDuration is null, we assume it’s still “In Progress”
    final durationString = entry.eventDuration != null
        ? _formatDuration(entry.eventDuration!)
        : 'In Progress';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1) Start date/time
          Expanded(flex: 3, child: Text(startString)),

          // 2) Duration or In Progress
          Expanded(
            flex: 2,
            child: Text(durationString, textAlign: TextAlign.center),
          ),

          // 3) Garden-feature identifier
          Expanded(
            flex: 2,
            child: Text(entry.featureName, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  /// Utility to format a DateTime into `DD/MM/YYYY HH:MM`
  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Utility to format a Duration into `Xm Ys`
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
