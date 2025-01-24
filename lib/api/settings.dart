import 'dart:io';

const debugServerUrl = 'http://localhost:1080';

const releaseServerUrl = 'http://irrigation';

// ignore: do_not_use_environment
String serverUrl = Platform.environment['SERVER_URL'] ?? 'http://irrigation';
