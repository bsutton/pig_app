const debugServerUrl = 'http://localhost:1080';

const releaseServerUrl = 'http://irrigation';

// ignore: do_not_use_environment
String serverUrl = const String.fromEnvironment('SERVER_URL',
    defaultValue: 'http://irrigation');
