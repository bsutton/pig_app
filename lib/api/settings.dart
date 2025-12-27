import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../util/server_settings.dart';

// ignore: do_not_use_environment
String get serverUrl => ServerSettings.serverUrlOverride ??
    (ServerSettings.webFallbackServerUrl() ??
        (dotenv.env['SERVER_URL'] ?? 'https://squarephone.biz'));

String get webSocketUrl =>
    ServerSettings.webSocketUrlOverride ??
    (ServerSettings.toWebSocketUrl(serverUrl) ??
        (ServerSettings.webFallbackWebSocketUrl() ??
            (dotenv.env['WS_SERVER_URL'] ?? 'wss://squarephone.biz')));
