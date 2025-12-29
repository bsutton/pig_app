// lib/src/ui/overview/overview_screen.dart

import 'package:deferred_state/deferred_state.dart';
import 'package:flutter/material.dart';
import 'package:pig_common/pig_common.dart';

import '../../api/overview_api.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends DeferredState<OverviewScreen> {
  late final OverviewData? _overviewData;

  final api = OverviewApi();

  @override
  Future<void> asyncInitState() async {
    // Now this call internally fetches both (a) your app’s “counts/events”
    // and (b) the BOM weather. By the time it completes, _overviewData.temp,
    // are all populated.
    _overviewData = await api.fetchOverviewData();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Overview')),
    body: DeferredBuilder(
      this,
      builder: (context) {
        if (_overviewData == null) {
          return const Center(child: Text('No data available'));
        }

        // If no garden beds, show the “getting started” message
        if (_overviewData.gardenBedsCount == 0) {
          return _buildGettingStarted(context, _overviewData);
        } else {
          return _buildOverview(context, _overviewData);
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

An End Point is a Valve or Light associated with a physical Raspberry Pi GPIO
Pin.

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

    return Padding(padding: const EdgeInsets.all(16), child: Text(message));
  }

  Widget _buildOverview(
    BuildContext context,
    OverviewData data,
  ) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeatherSource(data),
        const SizedBox(height: 8),
        // Now that OverviewData.temp was populated via BomApi,
        // this will show the live current temperature:
        Text('Current Temp: ${data.temp.toStringAsFixed(1)} °C'),
        const SizedBox(height: 8),
        Text('Forecast High: ${data.forecastHigh.toStringAsFixed(1)} °C'),
        Text('Forecast Low: ${data.forecastLow.toStringAsFixed(1)} °C'),
        const SizedBox(height: 8),
        const Text('Rain Data'),
        Text('Last 24 Hours: ${data.rain24.toStringAsFixed(1)} mm'),
        Text('Last 7 days: ${data.rain7days.toStringAsFixed(1)} mm'),
        const SizedBox(height: 12),
        const Text('3-Day Forecast'),
        if (data.rainForecastNext3Days.isEmpty)
          const Text('No forecast available.')
        else
          for (final day in data.rainForecastNext3Days)
            _buildForecastRow(day),
        const SizedBox(height: 16),
        const Text('Watering Events:'),
        for (final event in data.lastWateringEvents) _buildHistoryRow(event),
      ],
    ),
  );

  Widget _buildWeatherSource(OverviewData data) {
    final parts = <String>[];
    if (data.weatherBureauName.isNotEmpty) {
      parts.add(data.weatherBureauName);
    }
    if (data.weatherStationName.isNotEmpty) {
      parts.add(data.weatherStationName);
    }
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text('Weather Source: ${parts.join(' - ')}');
  }

  Widget _buildHistoryRow(WateringEvent event) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(formatDate(event.start)),
      Text('${event.durationMinutes} min'),
      Text(event.gardenBedName),
    ],
  );

  Widget _buildForecastRow(WeatherDayForecastData day) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(day.date)),
        Text('${day.minTempC.toStringAsFixed(0)}–${day.maxTempC.toStringAsFixed(0)} °C'),
        Text('${day.rainMinMm.toStringAsFixed(0)}–${day.rainMaxMm.toStringAsFixed(0)} mm'),
        Text('${day.rainChancePercent.toStringAsFixed(0)}%'),
      ],
    ),
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
