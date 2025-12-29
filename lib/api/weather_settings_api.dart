import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pig_common/pig_common.dart';

import '../util/exceptions.dart';
import 'auth_headers.dart';
import 'settings.dart';

class WeatherSettingsApi {
  Future<List<WeatherLocationData>> searchLocations(String query) async {
    final uri = Uri.parse('$serverUrl/weather/search');
    final resp = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode({'query': query}),
    );
    if (resp.statusCode != 200) {
      throw NetworkException(resp, action: 'Searching weather locations');
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final locations = decoded['locations'] as List<dynamic>? ?? [];
    return locations
        .map((e) => WeatherLocationData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WeatherLocationData> getLocation() async {
    final uri = Uri.parse('$serverUrl/weather/location');
    final resp = await http.post(uri, headers: jsonHeaders(), body: jsonEncode({}));
    if (resp.statusCode != 200) {
      throw NetworkException(resp, action: 'Fetching weather location');
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    return WeatherLocationData.fromJson(decoded);
  }

  Future<WeatherLocationData> setLocation(WeatherLocationData location) async {
    final uri = Uri.parse('$serverUrl/weather/location');
    final resp = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode(location.toJson()),
    );
    if (resp.statusCode != 200) {
      throw NetworkException(resp, action: 'Saving weather location');
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    return WeatherLocationData.fromJson(decoded);
  }
}
