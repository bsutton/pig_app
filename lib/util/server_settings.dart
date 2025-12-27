import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerSettings {
  static const _serverUrlKey = 'server_url_override';
  static const _wsUrlKey = 'ws_url_override';

  static String? _serverUrlOverride;
  static String? _webSocketUrlOverride;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrlOverride = _cleanUrl(prefs.getString(_serverUrlKey));
    _webSocketUrlOverride = _cleanUrl(prefs.getString(_wsUrlKey));
  }

  static String? get serverUrlOverride => _serverUrlOverride;

  static String? get webSocketUrlOverride => _webSocketUrlOverride;

  static Future<void> setServerUrlOverride(String? value) async {
    _serverUrlOverride = _cleanUrl(value);
    final prefs = await SharedPreferences.getInstance();
    if (_serverUrlOverride == null) {
      await prefs.remove(_serverUrlKey);
    } else {
      await prefs.setString(_serverUrlKey, _serverUrlOverride!);
    }
  }

  static Future<void> setWebSocketUrlOverride(String? value) async {
    _webSocketUrlOverride = _cleanUrl(value);
    final prefs = await SharedPreferences.getInstance();
    if (_webSocketUrlOverride == null) {
      await prefs.remove(_wsUrlKey);
    } else {
      await prefs.setString(_wsUrlKey, _webSocketUrlOverride!);
    }
  }

  static String? _cleanUrl(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  static String? toWebSocketUrl(String? serverUrl) {
    if (serverUrl == null) {
      return null;
    }
    final uri = Uri.tryParse(serverUrl);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  static String? webFallbackServerUrl() {
    if (!kIsWeb) {
      return null;
    }
    final base = Uri.base;
    if (base.host.isEmpty) {
      return null;
    }
    return base.origin;
  }

  static String? webFallbackWebSocketUrl() {
    if (!kIsWeb) {
      return null;
    }
    final base = Uri.base;
    if (base.host.isEmpty) {
      return null;
    }
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
    ).toString();
  }
}
