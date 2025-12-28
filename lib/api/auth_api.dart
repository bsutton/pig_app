import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../util/auth_crypto.dart';
import '../util/auth_store.dart';
import '../util/exceptions.dart';
import 'settings.dart';

class AuthApi {
  static const _timeout = Duration(seconds: 10);

  Future<AuthChallenge> requestChallenge() async {
    final uri = Uri.parse('$serverUrl/auth/challenge');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Fetching auth challenge');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthChallenge.fromJson(data);
  }

  Future<void> login(String password) async {
    final overall = Stopwatch()..start();
    final challenge = await requestChallenge();
    developer.log(
      'Auth challenge received in ${overall.elapsedMilliseconds}ms',
      name: 'pig_app.auth',
    );
    final deriveTimer = Stopwatch()..start();
    final key = await AuthCrypto.deriveKey(
      password: password,
      saltBase64: challenge.salt,
      params: challenge.params,
      algorithm: challenge.algorithm,
    );
    deriveTimer.stop();
    developer.log(
      'Auth key derived in ${deriveTimer.elapsedMilliseconds}ms',
      name: 'pig_app.auth',
    );
    final responseHex = AuthCrypto.hmacHex(
      key,
      'pigation:${challenge.nonce}',
    );
    final uri = Uri.parse('$serverUrl/auth/login');
    final requestTimer = Stopwatch()..start();
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nonce': challenge.nonce,
        'response': responseHex,
      }),
    ).timeout(_timeout);
    requestTimer.stop();
    developer.log(
      'Auth login response in ${requestTimer.elapsedMilliseconds}ms',
      name: 'pig_app.auth',
    );
    if (response.statusCode != 200) {
      var message = 'Login failed.';
      try {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        final error = errorJson['error'] as String?;
        if (error != null && error.isNotEmpty) {
          message = error;
        }
      } on Exception {
        message = 'Login failed (status ${response.statusCode}).';
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        message = 'Invalid password.';
      }
      throw IrrigationAppException(message);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final expiresIn = Duration(seconds: data['expiresIn'] as int);
    await AuthStore.setToken(token, expiresIn);
    overall.stop();
    developer.log(
      'Auth login completed in ${overall.elapsedMilliseconds}ms',
      name: 'pig_app.auth',
    );
  }
}

class AuthChallenge {
  AuthChallenge({
    required this.nonce,
    required this.salt,
    required this.params,
    required this.algorithm,
  });

  final String nonce;
  final String salt;
  final List<int> params;
  final String algorithm;

  factory AuthChallenge.fromJson(Map<String, dynamic> json) => AuthChallenge(
        nonce: json['nonce'] as String,
        salt: json['salt'] as String,
        params: (json['params'] as List<dynamic>)
            .map((value) => value as int)
            .toList(),
        algorithm: json['algorithm'] as String,
      );
}
