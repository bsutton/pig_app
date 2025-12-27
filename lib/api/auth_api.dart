import 'dart:convert';

import 'package:http/http.dart' as http;

import '../util/auth_crypto.dart';
import '../util/auth_store.dart';
import '../util/exceptions.dart';
import 'settings.dart';

class AuthApi {
  Future<AuthChallenge> requestChallenge() async {
    final uri = Uri.parse('$serverUrl/auth/challenge');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Fetching auth challenge');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthChallenge.fromJson(data);
  }

  Future<void> login(String password) async {
    final challenge = await requestChallenge();
    final key = AuthCrypto.deriveKey(
      password: password,
      saltBase64: challenge.salt,
      params: challenge.params,
      algorithm: challenge.algorithm,
    );
    final responseHex = AuthCrypto.hmacHex(
      key,
      'pigation:${challenge.nonce}',
    );
    final uri = Uri.parse('$serverUrl/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nonce': challenge.nonce,
        'response': responseHex,
      }),
    );
    if (response.statusCode != 200) {
      throw NetworkException(response, action: 'Logging in');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final expiresIn = Duration(seconds: data['expiresIn'] as int);
    await AuthStore.setToken(token, expiresIn);
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
