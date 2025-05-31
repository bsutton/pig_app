// lib/src/api/bom_api.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../util/exceptions.dart';

/// A simple data‐holder for all the weather fields we need.
class WeatherInfo {
  WeatherInfo({
    required this.currentTempC,
    required this.forecastHighC,
    required this.forecastLowC,
    required this.rainLast24mm,
    required this.rainLast7Daysmm,
  });

  final double currentTempC;
  final double forecastHighC;
  final double forecastLowC;
  final double rainLast24mm;
  final double rainLast7Daysmm;
}

class BomApi {
  BomApi({this.stationId = 'IDK60904'});

  /// The base URL for BOM’s JSON REST endpoints. Adjust if your BOM service
  /// is hosted elsewhere (some teams proxy BOM data through their own server).
  // static const _base = 'https://api.bom.gov.au';

  static const _base = 'https://api.weather.bom.gov.au/v1';

  /// You will need to pick a station ID (e.g. “IDK60904” for Melbourne CBD).
  /// Alternatively, store this in settings or let the user pick a station.
  final String stationId;

  /// Fetches everything in parallel:
  ///   • current temperature
  ///   • forecast high / low
  ///   • rain in last 24 h
  ///   • rain in last 7 days
  ///
  /// RETURNS a [WeatherInfo] with all fields populated (or throws on failure).
  Future<WeatherInfo> fetchWeather() async {
    // 1. Build all four URIs:
    final uriObs = Uri.parse('$_base/bom-observations?stationId=$stationId');
    final uriForecast = Uri.parse('$_base/bom-forecast?stationId=$stationId');
    final uriRain24 = Uri.parse(
      '$_base/bom-rain?stationId=$stationId&period=24h',
    );
    final uriRain7d = Uri.parse(
      '$_base/bom-rain?stationId=$stationId&period=7d',
    );

    // 2. Fire off all four requests concurrently:
    final futures = await Future.wait([
      http.get(uriObs),
      http.get(uriForecast),
      http.get(uriRain24),
      http.get(uriRain7d),
    ]);

    // 3. Validate each response status == 200:
    for (final r in futures) {
      if (r.statusCode != 200) {
        throw NetworkException(r, action: 'Fetching BOM weather');
      }
    }

    // 4. Parse each payload:
    final obsJson = jsonDecode(futures[0].body) as Map<String, dynamic>;
    final forecastJson = jsonDecode(futures[1].body) as Map<String, dynamic>;
    final rain24Json = jsonDecode(futures[2].body) as Map<String, dynamic>;
    final rain7dJson = jsonDecode(futures[3].body) as Map<String, dynamic>;

    // 5. Extract the fields you need. The exact JSON structure depends on your BOM API:
    final currentTempC = (obsJson['temp_c'] as num).toDouble();
    final forecastHighC = (forecastJson['forecast_high_c'] as num).toDouble();
    final forecastLowC = (forecastJson['forecast_low_c'] as num).toDouble();
    final rainLast24mm = (rain24Json['rain_mm_24h'] as num).toDouble();
    final rainLast7Daysmm = (rain7dJson['rain_mm_7d'] as num).toDouble();

    return WeatherInfo(
      currentTempC: currentTempC,
      forecastHighC: forecastHighC,
      forecastLowC: forecastLowC,
      rainLast24mm: rainLast24mm,
      rainLast7Daysmm: rainLast7Daysmm,
    );
  }
}
