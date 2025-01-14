// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pig_common/pig_common.dart';

import '../util/exceptions.dart';
import 'settings.dart';

class GardenBedApi {
  Future<GardenBedListData> fetchGardenBeds() async {
    final uri = Uri.parse('$serverUrl/garden_bed/list');
    final response = await http.post(uri, body: jsonEncode({}), headers: {
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GardenBedListData.fromJson(data);
    } else {
      throw NetworkException(response, action: 'Failed to load garden beds');
    }
  }

  /// if the [bedId] is null we it just means we are going to
  /// add a new bed but we need the list of available valves/master
  /// valves which this call fetches.
  Future<GardenBedListData> fetchBedEditData(int? bedId) async {
    final url = Uri.parse('$serverUrl/garden_bed/edit_data');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'gardenBedId': bedId}),
    );

    if (response.statusCode == 200) {
      final bedData = GardenBedListData.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);

      return bedData;
    }
    throw NetworkException(response, action: 'Loading Bed data for $bedId');
  }

  Future<void> toggleBed(
      {required GardenBedData bed, required bool turnOn}) async {
    final uri = Uri.parse('$serverUrl/garden_bed/toggle');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'bedId': bed.id, 'turnOn': turnOn}),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }

  Future<void> deleteBed(int bedId) async {
    final uri = Uri.parse('$serverUrl/garden_bed/delete');
    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bedId': bedId}));

    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }

  Future<void> save({
    required String name,
    required String description,
    required int valveId,
    int? id,
    int? masterValveId,
  }) async {
    final uri = Uri.parse('$serverUrl/garden_bed/save');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'name': name,
        'description': description,
        'valve_id': valveId,
        'master_valve_id': masterValveId,
      }),
    );

    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }
}
