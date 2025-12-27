// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pig_common/pig_common.dart';

import '../util/exceptions.dart';
import 'auth_headers.dart';
import 'settings.dart';

class GardenBedApi {
  Future<GardenBedListData> fetchGardenBeds() async {
    final uri = Uri.parse('$serverUrl/garden_bed/list');
    final response = await http.post(
      uri,
      body: jsonEncode({}),
      headers: jsonHeaders(),
    );
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
      headers: jsonHeaders(),
      body: jsonEncode({'gardenBedId': bedId}),
    );

    if (response.statusCode == 200) {
      final bedData = GardenBedListData.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      return bedData;
    }
    throw NetworkException(response, action: 'Loading Bed data for $bedId');
  }

  Future<void> toggleBed({
    required GardenBedData bed,
    required bool turnOn,
  }) async {
    final uri = Uri.parse('$serverUrl/garden_bed/toggle');
    final response = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode({'bedId': bed.id, 'turnOn': turnOn}),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }

  Future<void> deleteBed(int bedId) async {
    final uri = Uri.parse('$serverUrl/garden_bed/delete');
    final response = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode({'bedId': bedId}),
    );

    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }

  Future<void> save(GardenBedData bed) async {
    final uri = Uri.parse('$serverUrl/garden_bed/save');
    final response = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode(bed.toJson()),
    );

    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }

  Future<void> startTimer(
    int bedId,
    Duration duration,
    String description,
  ) async {
    final url = Uri.parse('$serverUrl/garden_bed/start_timer');
    final http.Response response;
    try {
      print('trying');
      response = await http.post(
        url,
        headers: jsonHeaders(),
        body: jsonEncode({
          'bedId': bedId,
          'durationSeconds': duration.inSeconds,
          'description': description,
        }),
      );
      print('returned');
      if (response.statusCode != 200) {
        throw NetworkException(response);
      }
    } on NetworkException {
      rethrow;
    } on Exception catch (e) {
      throw NetworkException.fromException(e, action: 'Starting timer');
    }
  }

  Future<void> stopTimer(int bedId) async {
    final url = Uri.parse('$serverUrl/garden_bed/stop_timer');
    final response = await http.post(
      url,
      headers: jsonHeaders(),
      body: jsonEncode({'bedId': bedId}),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }
}
