import 'dart:js_interop' as js;

import 'package:flutter_dotenv/flutter_dotenv.dart';

String get releaseServerUrl => origin; // 'http://irrigation';

// ignore: do_not_use_environment
String serverUrl = dotenv.env['SERVER_URL'] ?? releaseServerUrl;

String webSocketUrl = dotenv.env['WS_SERVER_URL'] ?? wsSocketUrl;

String get origin => getOrigin();

String get wsSocketUrl {
  // Get the current server's origin using JS interop
  final origin = getOrigin();

  // Determine if the origin is using https or http and adjust the WebSocket protocol
  final wsProtocol = origin.startsWith('https') ? 'wss' : 'ws';

  // Replace the protocol and append the WebSocket port or endpoint
  final wsUrl = '${origin.replaceFirst(RegExp('^https?'), wsProtocol)}:1080';

  return wsUrl;
}

/// JS interop function to access `window.location.origin`
@js.JS()
external String getOrigin();
