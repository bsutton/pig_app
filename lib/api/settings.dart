import 'package:flutter_dotenv/flutter_dotenv.dart';

// ignore: do_not_use_environment
String serverUrl =
    dotenv.env['SERVER_URL'] ?? 'http://localhost:1080'; 

String webSocketUrl = dotenv.env['WS_SERVER_URL'] ?? 'ws://localhost:1080';
