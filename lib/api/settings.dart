import 'package:flutter_dotenv/flutter_dotenv.dart';

const wsSocketUrl = 'ws://irrigation:1080';

const releaseServerUrl = 'http://irrigation';

// ignore: do_not_use_environment
String serverUrl = dotenv.env['SERVER_URL'] ?? releaseServerUrl;

String webSocketUrl = dotenv.env['WS_SERVER_URL'] ?? wsSocketUrl;
