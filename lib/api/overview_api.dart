import 'dart:convert';

import 'package:http/http.dart' as http;

import 'settings.dart';

class OverviewApi {
  Future<OverviewData> fetchOverviewData() async {
    final uri = Uri.parse('$serverUrl/overview');
    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({})); // no request body needed in example
    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return OverviewData.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load overview: ${response.body}');
    }
  }
}

/// Data class for entire overview payload
class OverviewData {
  OverviewData({
    required this.gardenBedsCount,
    required this.endpointsCount,
    required this.temp,
    required this.forecastHigh,
    required this.forecastLow,
    required this.rain24,
    required this.rain7days,
    required this.lastWateringEvents,
  });

  factory OverviewData.fromJson(Map<String, dynamic> json) {
    final events = (json['lastWateringEvents'] as List<dynamic>?)
        ?.map((e) => WateringEvent.fromJson(e as Map<String, dynamic>))
        .toList();

    return OverviewData(
      gardenBedsCount: json['gardenBedsCount'] as int,
      endpointsCount: json['endpointsCount'] as int,
      temp: json['temp'] as int,
      forecastHigh: json['forecastHigh'] as int,
      forecastLow: json['forecastLow'] as int,
      rain24: json['rain24'] as int,
      rain7days: json['rain7days'] as int,
      lastWateringEvents: events ?? [],
    );
  }
  final int gardenBedsCount;
  final int endpointsCount;
  final int temp;
  final int forecastHigh;
  final int forecastLow;
  final int rain24;
  final int rain7days;
  final List<WateringEvent> lastWateringEvents;
}

/// Data class for watering events
class WateringEvent {
  WateringEvent({
    required this.start,
    required this.durationMinutes,
    required this.gardenBedName,
  });

  factory WateringEvent.fromJson(Map<String, dynamic> json) => WateringEvent(
        start: DateTime.parse(json['start'] as String),
        durationMinutes: json['durationMinutes'] as int,
        gardenBedName: json['gardenBedName'] as String,
      );
  final DateTime start;
  final int durationMinutes;
  final String gardenBedName;
}
