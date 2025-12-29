import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../util/server_settings.dart';

String? _readEnv(String key) {
  if (!dotenv.isInitialized) {
    return null;
  }
  final value = dotenv.env[key];
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value;
}

// ignore: do_not_use_environment
String get serverUrl => ServerSettings.serverUrlOverride ??
    (ServerSettings.webFallbackServerUrl() ??
        (_readEnv('SERVER_URL') ?? 'https://squarephone.biz'));

String get webSocketUrl =>
    ServerSettings.webSocketUrlOverride ??
    (ServerSettings.toWebSocketUrl(serverUrl) ??
        (ServerSettings.webFallbackWebSocketUrl() ??
            (_readEnv('WS_SERVER_URL') ?? 'wss://squarephone.biz')));
