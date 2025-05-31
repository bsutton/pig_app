import 'package:flutter_dotenv/flutter_dotenv.dart';

// ignore: do_not_use_environment
String serverUrl =
    dotenv.env['SERVER_URL'] ?? 'https://squarephone.biz'; 

String webSocketUrl = dotenv.env['WS_SERVER_URL'] ?? 'wss://squarephone.biz';
