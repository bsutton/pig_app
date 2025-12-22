// lib/src/api/bom_api.dart

// ignore_for_file: avoid_dynamic_calls

import 'weather_api.dart';

/// A helper “summary” object that mirrors the Python `Summary` class:
///   • location
///   • warnings
///   • observations
///   • forecast_rain
///   • forecasts_daily
///   • forecasts_hourly
///
/// Plus helper methods to build a simple dictionary of “label/value/unit” entries.
class WeatherSummary {
  final WeatherApi _api;

  Map<String, dynamic>? locationData;

  List<Map<String, dynamic>> warningsData = [];

  Map<String, dynamic>? observationsData;

  Map<String, dynamic>? forecastRainData;

  List<Map<String, dynamic>> dailyData = [];

  List<Map<String, dynamic>> hourlyData = [];

  WeatherSummary({String? geohash, String? search, bool debug = false})
    : _api = WeatherApi(geohash: geohash, search: search, debug: debug);

  /// Call this first to populate everything
  Future<void> refresh() async {
    locationData = (await _api.location())?.toJson();
    warningsData = await _api.warnings();
    observationsData = await _api.observations();
    forecastRainData = await _api.forecastRain();
    dailyData = await _api.forecastsDaily();
    hourlyData = await _api.forecastsHourly();
  }

  /// Returns an ordered map of “label → (value, unit)” for the first two days
  /// of the daily forecast and the current observations—mimicking Python `summary()`.
  Map<String, Map<String, String>> summary() {
    final result = <String, Map<String, String>>{};

    // Location
    final loc = locationData == null
        ? '--'
        : '${locationData!['name']}, ${locationData!['state']}';
    result['Location'] = {'value': loc, 'unit': ''};

    // Current Temp
    if (observationsData != null && observationsData!['temp'] != null) {
      result['Current Temp'] = {
        'value': observationsData!['temp'].toString(),
        'unit': '°C',
      };
    }

    // Daily forecasts: we expect at least two days in dailyData
    if (dailyData.isNotEmpty) {
      final today = dailyData[0];
      // final tomorrow = dailyData.length > 1 ? dailyData[1] : null;

      // Precis (short_text)
      final precis = today['short_text']?.toString() ?? '--';
      result['Precis'] = {'value': precis, 'unit': ''};

      // “Now” temperatures under dailyData[0]['now']
      if (today['now'] != null) {
        final nowBlock = today['now'] as Map<String, dynamic>;
        result[nowBlock['now_label'] as String] = {
          'value': nowBlock['temp_now'].toString(),
          'unit': '°C',
        };
        result[nowBlock['later_label'] as String] = {
          'value': nowBlock['temp_later'].toString(),
          'unit': '°C',
        };
      }

      // Feels Like
      if (observationsData != null &&
          observationsData!['temp_feels_like'] != null) {
        result['Feels Like'] = {
          'value': observationsData!['temp_feels_like'].toString(),
          'unit': '°C',
        };
      }

      // Chance of any rain (today’s rain chance)
      final rainChance = (today['rain'] != null)
          ? (today['rain']['chance']?.toString() ?? '--')
          : '--';
      result['Chance of Rain'] = {'value': rainChance, 'unit': '%'};

      // Possible rainfall (min–max)
      if (today['rain'] != null && today['rain']['amount'] != null) {
        final amt = today['rain']['amount'] as Map<String, dynamic>;
        final maxAmt = amt['max'];
        if (maxAmt != null && (maxAmt as num) > 0) {
          final minAmt = amt['min']?.toString() ?? '0';
          final units = amt['units']?.toString() ?? 'mm';
          result['Possible Rainfall'] = {
            'value': '$minAmt–$maxAmt',
            'unit': units,
          };
        }
      }
    }

    return result;
  }

  /// Build a multi-line text representation, much like Python’s `summary_text()`.
  String summaryText() {
    final buf = StringBuffer();
    final items = summary();
    for (final key in items.keys) {
      final label = key.padRight(20);
      final val = items[key]!['value'];
      final unit = items[key]!['unit'];
      buf.writeln('$label $val $unit');
    }
    buf
      ..writeln()
      ..writeln('Data courtesy of BOM API');
    return buf.toString();
  }

  /// A small `today()` equivalent returning the extended text if present.
  Map<String, dynamic> today() {
    if (dailyData.isNotEmpty) {
      final today = dailyData[0];
      return {'extended_text': today['extended_text'] ?? ''};
    }
    return {};
  }
}
