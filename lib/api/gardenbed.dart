// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../util/exceptions.dart';
import 'settings.dart';

class GardenBedApi {
  Future<List<GardenBedInfo>> fetchGardenBeds() async {
    final uri = Uri.parse('$serverUrl/garden_bed/list');
    final response = await http.post(uri, body: jsonEncode({}), headers: {
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['beds'] as List<dynamic>;
      return list
          .map((bed) => GardenBedInfo.fromJson(bed as Map<String, dynamic>))
          .toList();
    } else {
      throw NetworkException(response, action: 'Failed to load garden beds');
    }
  }

  Future<GardenBedData> fetchBed(int bedId) async {
    final url = Uri.parse('$serverUrl/garden_bed/edit_data');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'gardenBedId': bedId}),
    );

    final bedData = GardenBedData(name: 'Please set');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      // parse bed
      final bedJson = body['bed'];
      if (bedJson != null) {
        bedData
          ..id = bedJson['id'] as int?
          ..name = bedJson['name'] as String? ?? ''
          ..valveId = bedJson['valveId'] as int?
          ..masterValveId = bedJson['masterValveId'] as int?
          ..allowDelete = true;
      }

      // parse valves
      final valvesList = body['valves'] as List<dynamic>? ?? [];
      bedData.valves = valvesList
          .map((json) => EndPointInfo.fromJson(json as Map<String, dynamic>))
          .toList();

      // parse masterValves
      final masterValvesList = body['masterValves'] as List? ?? [];
      bedData.masterValves = masterValvesList
          .map((json) => EndPointInfo.fromJson(json! as Map<String, dynamic>))
          .toList();
    } else {
      throw NetworkException(response, action: 'Loading Bed data for $bedId');
    }
    return bedData;
  }

  Future<void> toggleBed(
      {required GardenBedInfo bed, required bool turnOn}) async {
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

  Future<void> save(
      {required String name,
      required int valveId,
      int? id,
      int? masterValveId}) async {
    final uri = Uri.parse('$serverUrl/garden_bed/save');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'name': name,
        'valve_id': valveId,
        'master_valve_id': masterValveId
      }),
    );

    if (response.statusCode != 200) {
      throw NetworkException(response);
    }
  }
}

class GardenBedInfo {
  GardenBedInfo({required this.id, required this.name, required this.isOn});

  factory GardenBedInfo.fromJson(Map<String, dynamic> json) => GardenBedInfo(
        id: json['id'] as int,
        name: json['name'] as String,
        isOn: json['isOn'] as bool,
      );
  final int id;
  final String name;
  final bool isOn;
}

class GardenBedData {
  GardenBedData({
    required this.name,
    this.id,
    this.valveId,
    this.masterValveId,
    this.allowDelete = false,
    this.valves = const <EndPointInfo>[],
    this.masterValves = const <EndPointInfo>[],
  });
  int? id;
  String name;
  int? valveId;
  int? masterValveId;
  bool allowDelete;

  /// List of available valves
  List<EndPointInfo> valves;

  /// List of available master valves
  List<EndPointInfo> masterValves;
}

class EndPointInfo {
  EndPointInfo({required this.id, required this.name, required this.pinNo});

  factory EndPointInfo.fromJson(Map<String, dynamic> json) => EndPointInfo(
        id: json['id'] as int,
        name: json['name'] as String,
        pinNo: json['pinNo'] as int,
      );
  final int id;
  final String name;
  final int pinNo;
}
