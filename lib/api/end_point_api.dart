// end_point_api.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pig_common/pig_common.dart';

import '../util/exceptions.dart';
import 'auth_headers.dart';
import 'settings.dart';

class EndPointApi {
  /// Fetches all endpoints plus optional weather data
  /// POST /end_point/list
  Future<EndPointListData> listEndPoints() async {
    final uri = Uri.parse('$serverUrl/end_point/list');
    final response = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode({}), // no body needed
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return EndPointListData.fromJson(body);
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
      headers: jsonHeaders(),
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
    required EndPoint endPoint,
    // required String name,
    // required int ordinal,
    // required GPIOPinAssignment pinAssignment,
    // required PinActivationType activationType,
    // required EndPointType endPointType,
    int? id,
  }) async {
    final uri = Uri.parse('$serverUrl/end_point/save');

    final body = EndPointData(
      id: id,
      ordinal: endPoint.ordinal,
      name: endPoint.name,
      activationType: endPoint.activationType,
      gpioPinAssignment: GPIOPinAssignment.getByPinNo(endPoint.gpioPinNo),
      endPointType: endPoint.endPointType,
      isOn: false,
    ).toJson();
    final response = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Saving EndPoint');
    }
  }

  /// Save or update an EndPoint using a pre-built DTO.
  Future<void> saveEndPointData({required EndPointData endPoint}) async {
    final uri = Uri.parse('$serverUrl/end_point/save');
    final response = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode(endPoint.toJson()),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Saving EndPoint');
    }
  }

  /// Toggle an endpoint on or off
  /// POST /end_point/toggle
  Future<void> toggleEndPoint({
    required int endPointId,
    required bool turnOn,
  }) async {
    final uri = Uri.parse('$serverUrl/end_point/toggle');
    final response = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode({'endPointId': endPointId, 'turnOn': turnOn}),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Toggling EndPoint');
    }
  }

  /// Pulse a GPIO pin without requiring an endpoint mapping.
  /// POST /end_point/pulse_pin
  Future<void> pulsePin({
    required int pinNo,
    required int durationMs,
    PinActivationType activationType = PinActivationType.highIsOn,
  }) async {
    final uri = Uri.parse('$serverUrl/end_point/pulse_pin');
    final response = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode({
        'pinNo': pinNo,
        'durationMs': durationMs,
        'activationType': activationType.name,
      }),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Pulsing Pin');
    }
  }

  /// Delete an endpoint
  /// POST /end_point/delete
  Future<void> deleteEndPoint(int endPointId) async {
    final uri = Uri.parse('$serverUrl/end_point/delete');
    final response = await http.post(
      uri,
      headers: jsonHeaders(),
      body: jsonEncode({'endPointId': endPointId}),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Deleting EndPoint');
    }
  }
}
