import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  static const _tokenKey = 'auth_token';
  static const _expiryKey = 'auth_token_expiry';

  static String? _token;
  static DateTime? _expiry;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final expiryMillis = prefs.getInt(_expiryKey);
    _expiry = expiryMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(expiryMillis);
  }

  static String? get token => _token;

  static bool get isLoggedIn {
    if (_token == null || _token!.isEmpty) {
      return false;
    }
    if (_expiry == null) {
      return true;
    }
    return DateTime.now().isBefore(_expiry!);
  }

  static Future<void> setToken(String token, Duration expiresIn) async {
    _token = token;
    _expiry = DateTime.now().add(expiresIn);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_expiryKey, _expiry!.millisecondsSinceEpoch);
  }

  static Future<void> clear() async {
    _token = null;
    _expiry = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiryKey);
  }
}
