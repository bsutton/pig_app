import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pig_common/pig_common.dart';

import '../util/exceptions.dart';

/// After adding these imports, make sure you import BomApi below.
import 'bom_api.dart';
import 'settings.dart';

class OverviewApi {
  final _bom = BomApi();

  /// Fetches both (a) the “home‐grown” overview data (counts of beds, etc.)
  /// and (b) the BOM weather. Then returns a combined `OverviewData`.
  Future<OverviewData> fetchOverviewData() async {
    // 1. Fetch whatever your existing server‐side endpoint returns:
    final uri = Uri.parse('$serverUrl/overview');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    if (resp.statusCode != 200) {
      throw NetworkException(resp, action: 'Fetching overview data');
    }

    // Parse the “garden‐bed / endpoint” portion of your API response:
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    // e.g. maybe your server returned:
    // {
    //   "gardenBedsCount": 3,
    //   "endpointsCount": 5,
    //   "lastWateringEvents": [ … ],
    //   "…otherFields…": …
    // }
    final serverOverview = OverviewData.fromJson(decoded);

    // // 2. Fetch BOM weather in parallel (or serially, if you prefer). Here we do it in parallel:
    // final weather = await _bom.fetchWeather();

    // // 3. Copy the new weather fields into our `serverOverview`:
    // serverOverview
    //   ..temp = weather.currentTempC
    //   ..forecastHigh = weather.forecastHighC
    //   ..forecastLow = weather.forecastLowC
    //   ..rain24 = weather.rainLast24mm
    //   ..rain7days = weather.rainLast7Daysmm;

    return serverOverview;
  }
}
