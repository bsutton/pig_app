import 'dart:convert';

import 'package:http/http.dart' as http;

import '../util/exceptions.dart';
import 'auth_headers.dart';
import 'lighting_info.dart';
import 'settings.dart';

class LightingApi {
  Future<List<LightingInfo>> fetchLightingList() async {
    final url = Uri.parse('$serverUrl/lighting/list');
    final response = await http.post(
      url,
      headers: jsonHeaders(),
      body: jsonEncode({}),
    ); // No request body needed in our example

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['lights'] as List<dynamic>;
      return list
          .map((e) => LightingInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load lighting info: ${response.body}');
    }
  }

  Future<void> toggle({
    required Duration duration,
    required LightingInfo light,
    required bool turnOn,
  }) async {
    final url = Uri.parse('$serverUrl/lighting/toggle');
    final response = await http.post(
      url,
      headers: jsonHeaders(),
      body: jsonEncode({
        'lightId': light.id,
        'turnOn': turnOn,
        'durationSeconds': duration.inSeconds,
      }),
    );

    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }

  Future<void> deleteLight(int lightId) async {
    final url = Uri.parse('$serverUrl/lighting/delete');
    final response = await http.post(
      url,
      headers: jsonHeaders(),
      body: jsonEncode({'lightId': lightId}),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }
}
