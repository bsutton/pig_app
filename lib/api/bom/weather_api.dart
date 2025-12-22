// lib/src/api/bom_api.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'bom_location.dart';

/// A thin wrapper around BOM’s various JSON endpoints:
///   • /locations/search?query=…
///   • /locations/lookup?geohash=…
///   • /observations/latest?geohash=…
///   • /forecasts/hourly?geohash=…
///   • /forecasts/daily?geohash=…
///   • /warnings?geohash=…
///   • /rain?geohash=…
///
/// These URIs come from reverse-engineering the Python library (weather_au/api.py).
/// Whenever BOM changes its service, just update the strings below.
class WeatherApi {
  /// If you want to search by postcode or place name, set `search`. Otherwise, set `geohash`.
  final String? geohash;

  final String? search;

  final bool debug;

  /// The BOM v1 base URL (reverse-engineered from Python code).
  static const _base = 'https://api.weather.bom.gov.au/v1/';

  BomLocation? _location;

  DateTime? responseTimestamp;

  WeatherApi({this.geohash, this.search, this.debug = false});

  /// Step 1: either search by “search” or lookup by “geohash”.
  /// On success, populates `_location` and returns it; else returns null.
  Future<BomLocation?> location() async {
    if (search != null && search!.isNotEmpty) {
      // e.g. GET /base + 'locations/search?query=3052'
      final u = Uri.parse(
        '${_base}locations/search?query=${Uri.encodeComponent(search!)}',
      );
      final resp = await http.get(u);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final features = decoded['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          _location = BomLocation.fromFeature(
            features.first as Map<String, dynamic>,
          );
          if (debug) {
            print('✔️ Found location: ${_location!.name}, ${_location!.state}');
          }
          return _location;
        }
      }
      if (debug) {
        print('❌ location() returned status ${resp.statusCode}: ${resp.body}');
      }
      return null;
    }

    if (geohash != null && geohash!.isNotEmpty) {
      // e.g. GET /base + 'locations/lookup?geohash=abcd1234'
      final u = Uri.parse('${_base}locations/lookup?geohash=$geohash');
      final resp = await http.get(u);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        _location = BomLocation.fromLookup(decoded);
        if (debug) {
          print(
            '✔️ Looked up location via geohash: ${_location!.name}, ${_location!.state}',
          );
        }
        return _location;
      }
      if (debug) {
        print('❌ lookup() returned status ${resp.statusCode}: ${resp.body}');
      }
      return null;
    }

    return null;
  }

  /// Step 2: Fetch any active warnings for this location.
  /// Python code’s `warnings()` probably hits `/warnings?geohash=…`.
  Future<List<Map<String, dynamic>>> warnings() async {
    if (_location == null) {
      await location();
      if (_location == null) {
        return <Map<String, dynamic>>[];
      }
    }
    final gh = _location!.geohash;
    final u = Uri.parse('${_base}warnings?geohash=$gh');
    final resp = await http.get(u);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      // Assume BOM’s warnings endpoint returns { data: [ {…}, {…}, … ] }
      return (decoded['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    }
    if (debug) {
      print('❌ warnings() failed: ${resp.statusCode}');
    }
    return <Map<String, dynamic>>[];
  }

  /// Step 3: Current observations (temperature, feels-like, humidity, etc.).
  /// Python code’s `observations()` likely calls `/observations/latest?geohash=…`.
  Future<Map<String, dynamic>?> observations() async {
    if (_location == null) {
      await location();
      if (_location == null) {
        return null;
      }
    }
    final gh = _location!.geohash;
    final u = Uri.parse('${_base}observations/latest?geohash=$gh');
    final resp = await http.get(u);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      // Typically BOM returns { data: { temp: …, temp_feels_like: …, … } }
      return decoded['data'] as Map<String, dynamic>?;
    }
    if (debug) {
      print('❌ observations() failed: ${resp.statusCode}');
    }
    return null;
  }

  /// Step 4: Hourly forecast
  Future<List<Map<String, dynamic>>> forecastsHourly() async {
    if (_location == null) {
      await location();
      if (_location == null) {
        return <Map<String, dynamic>>[];
      }
    }
    final gh = _location!.geohash;
    final u = Uri.parse('${_base}forecasts/hourly?geohash=$gh');
    final resp = await http.get(u);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      // Assume { data: { hours: [ { time: …, temp: …, …}, … ] } }
      final data = decoded['data'] as Map<String, dynamic>?;
      if (data != null && data['hours'] is List) {
        return (data['hours'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
    }
    if (debug) {
      print('❌ forecastsHourly() failed: ${resp.statusCode}');
    }
    return <Map<String, dynamic>>[];
  }

  /// Step 5: Daily forecast
  Future<List<Map<String, dynamic>>> forecastsDaily() async {
    if (_location == null) {
      await location();
      if (_location == null) {
        return <Map<String, dynamic>>[];
      }
    }
    final gh = _location!.geohash;
    final u = Uri.parse('${_base}forecasts/daily?geohash=$gh');
    final resp = await http.get(u);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      // Assume { data: [ { date: …, max_temp: …, min_temp: …, rain: { chance: …, amount: { min: …, max: …, units: … } }, …}, … ] }
      return (decoded['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    }
    if (debug) {
      print('❌ forecastsDaily() failed: ${resp.statusCode}');
    }
    return <Map<String, dynamic>>[];
  }

  /// Step 6: Rain forecast (24h and/or 7-day)
  /// Python’s `forecast_rain()` probably hits `/rain?geohash=…&period=XX`.
  Future<Map<String, dynamic>?> forecastRain({int hours = 24}) async {
    if (_location == null) {
      await location();
      if (_location == null) {
        return null;
      }
    }
    final gh = _location!.geohash;
    // BOM doesn’t officially document `/rain?geohash=xxx&period=24h`
    // in a public spec, but the Python library uses something like that.
    // You may need to confirm the exact query parameter names.
    final u = Uri.parse('${_base}rain?geohash=$gh&period=${hours}h');
    final resp = await http.get(u);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      return decoded['data'] as Map<String, dynamic>?;
    }
    if (debug) {
      print('❌ forecastRain() failed: ${resp.statusCode}');
    }
    return null;
  }

  /// A simple toString/repr equivalent.
  @override
  String toString() {
    final locDesc = _location == null
        ? ''
        : '${_location!.name}, ${_location!.state}';
    final ghDesc = geohash == null ? 'None' : "'$geohash'";
    return "WeatherApi(geohash=$ghDesc, search='$locDesc', debug=$debug)${responseTimestamp == null ? '' : ', timestamp=$responseTimestamp'}";
  }
}
