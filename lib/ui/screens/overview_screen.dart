// overview_screen.dart
import 'package:deferred_state/deferred_state.dart';
import 'package:flutter/material.dart';

import '../../api/overview_api.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends DeferredState<OverviewScreen> {
  late OverviewData? _overviewData;

  final api = OverviewApi();
  @override
  Future<void> asyncInitState() async {
    _overviewData = await api.fetchOverviewData();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Overview'),
        ),
        body: DeferredBuilder(
          this,
          builder: (context) {
            if (_overviewData == null) {
              return const Center(child: Text('No data available'));
            }

            // If no garden beds, show the “getting started” message
            if (_overviewData!.gardenBedsCount == 0) {
              return _buildGettingStarted(context, _overviewData!);
            } else {
              return _buildOverview(context, _overviewData!);
            }
          },
        ),
      );

  Widget _buildGettingStarted(BuildContext context, OverviewData data) {
    final endpointsExist = data.endpointsCount > 0;
    var message = '';
    if (!endpointsExist) {
      message = '''
To get started, you need to define one or more End Points.

An End Point is a Valve or Light, associating a physical Raspberry Pi pin.

To configure an End Point, select the 'Configuration' menu → 'End Points'.

Once you have an End Point, define each Light or Garden Bed.

For a Garden Bed, select 'Configuration' menu → 'Garden Beds'.
''';
    } else {
      message = '''
We have at least one End Point, but zero Garden Beds.

To configure a Garden Bed, select the 'Configuration' menu → 'Garden Beds'.
''';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(message),
    );
  }

  Widget _buildOverview(BuildContext context, OverviewData data) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Temp: ${data.temp} °C'),
            const SizedBox(height: 8),
            Text('Forecast High: ${data.forecastHigh} °C'),
            Text('Forecast Low: ${data.forecastLow} °C'),
            const SizedBox(height: 8),
            const Text('Rain Data'),
            Text('Last 24 Hours: ${data.rain24} mm'),
            Text('Last 7 days: ${data.rain7days} mm'),
            const SizedBox(height: 16),
            const Text('Watering Events:'),
            for (final event in data.lastWateringEvents)
              _buildHistoryRow(event),
          ],
        ),
      );

  Widget _buildHistoryRow(WateringEvent event) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(formatDate(event.start)),
          Text('${event.durationMinutes} min'),
          Text(event.gardenBedName),
        ],
      );

  /// Example format for a DateTime
  String formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
