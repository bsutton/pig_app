// end_point_api.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pig_common/pig_common.dart';

import '../util/exceptions.dart';
import 'settings.dart';

class EndPointApi {
  /// Fetches all endpoints plus optional weather data
  /// POST /end_point/list
  Future<EndPointListData> listEndPoints() async {
    final uri = Uri.parse('$serverUrl/end_point/list');
    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({})); // no body needed

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['endPoints'] as List<dynamic>? ?? [];
      final epList = list
          .map((e) => EndPointInfo.fromJson(e as Map<String, dynamic>))
          .toList();

      final bureauList = body['weatherBureaus'] as List<dynamic>? ?? [];
      final bureaus = bureauList
          .map((b) => WeatherBureauInfo.fromJson(b as Map<String, dynamic>))
          .toList(); // if you want them

      final stationList = body['weatherStations'] as List<dynamic>? ?? [];
      final stations = stationList
          .map((s) => WeatherStationInfo.fromJson(s as Map<String, dynamic>))
          .toList(); // if you want them

      return EndPointListData(
        endPoints: epList,
        bureaus: bureaus,
        stations: stations,
      );
    } else {
      throw NetworkException(response, action: 'Fetching EndPoints');
    }
  }

  /// Fetch data needed for editing an end point (existing or new).
  /// POST /end_point/edit_data
  Future<EndPointEditData> fetchEndPointEditData({int? endPointId}) async {
    final uri = Uri.parse('$serverUrl/end_point/edit_data');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'endPointId': endPointId}),
    );
    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return EndPointEditData.fromJson(jsonMap);
    } else {
      throw NetworkException(response, action: 'Fetching EndPoint Edit Data');
    }
  }

  /// Save or update an EndPoint
  /// For example: POST /end_point/save
  Future<void> saveEndPoint({
    required String name,
    required GPIOPinAssignment pinAssignment,
    required PinActivationType activationType,
    required EndPointType endPointType,
    int? id,
  }) async {
    final uri = Uri.parse('$serverUrl/end_point/save');

    final body = EndPointInfo(
            id: id,
            name: name,
            activationType: activationType,
            pinAssignment: pinAssignment,
            endPointType: endPointType,
            isOn: false)
        .toJson();
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Saving EndPoint');
    }
  }

  /// Toggle an endpoint on or off
  /// POST /end_point/toggle
  Future<void> toggleEndPoint(
      {required int endPointId, required bool turnOn}) async {
    final uri = Uri.parse('$serverUrl/end_point/toggle');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'endPointId': endPointId,
        'turnOn': turnOn,
      }),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Toggling EndPoint');
    }
  }

  /// Delete an endpoint
  /// POST /end_point/delete
  Future<void> deleteEndPoint(int endPointId) async {
    final uri = Uri.parse('$serverUrl/end_point/delete');
    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'endPointId': endPointId}));
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Deleting EndPoint');
    }
  }
}

/// Container for the list of endpoints and optional weather data
class EndPointListData {
  EndPointListData({
    required this.endPoints,
    required this.bureaus,
    required this.stations,
  });
  final List<EndPointInfo> endPoints;
  final List<WeatherBureauInfo> bureaus;
  final List<WeatherStationInfo> stations;
}

/// Minimal representation of a WeatherBureau
class WeatherBureauInfo {
  WeatherBureauInfo({required this.id, required this.countryName});

  factory WeatherBureauInfo.fromJson(Map<String, dynamic> json) =>
      WeatherBureauInfo(
        id: json['id'] as int,
        countryName: json['countryName'] as String,
      );

  final int id;
  final String countryName;
}

/// Minimal representation of a WeatherStation
class WeatherStationInfo {
  WeatherStationInfo({required this.id, required this.name});

  factory WeatherStationInfo.fromJson(Map<String, dynamic> json) =>
      WeatherStationInfo(
        id: json['id'] as int,
        name: json['name'] as String,
      );

  final int id;
  final String name;
}

/// Data returned from `/end_point/edit_data`
class EndPointEditData {
  EndPointEditData({
    required this.availablePins,
    required this.activationTypes,
    this.endPoint,
  });

  factory EndPointEditData.fromJson(Map<String, dynamic> json) {
    EndPointInfo? ep;
    final endPointJson = json['endPoint'] as Map<String, dynamic>?;
    if (endPointJson != null) {
      ep = EndPointInfo.fromJson(endPointJson);
      // You might store pinNo or activationType in a new data class, etc.
    }
    final pins = (json['availablePins'] as List<dynamic>? ?? [])
        .map((p) => GPIOPinAssignment.fromJson(p as Map<String, dynamic>))
        .toList();

    final acts = (json['activationTypes'] as List<dynamic>? ?? [])
        .map((a) => PinActivationType.fromJson(a as String))
        .toList();

    return EndPointEditData(
      endPoint: ep,
      availablePins: pins,
      activationTypes: acts,
    );
  }
  final EndPointInfo? endPoint; // null if new
  final List<GPIOPinAssignment> availablePins;
  final List<PinActivationType> activationTypes;
}
