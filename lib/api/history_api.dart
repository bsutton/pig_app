// lib/src/api/history_api.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pig_common/pig_common.dart';

import '../util/exceptions.dart';
import 'settings.dart';

class HistoryApi {
  Future<List<HistoryData>> fetchHistory() async {
    final url = Uri.parse('$serverUrl/history/list');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawList = decoded['history'] as List<dynamic>? ?? [];
      return rawList
          .map((e) => HistoryData.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw NetworkException(response);
    }
  }
}
