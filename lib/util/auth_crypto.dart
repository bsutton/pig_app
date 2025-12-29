import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

class AuthCrypto {
  static Future<Uint8List> deriveKey({
    required String password,
    required String saltBase64,
    required List<int> params,
    required String algorithm,
  }) async {
    if (params.length < 3) {
      throw ArgumentError('PBKDF2 params must include 3 values.');
    }
    final blockLength = params[0];
    final iterationCount = params[1];
    final desiredKeyLength = params[2];
    final salt = base64.decode(saltBase64);
    if (kIsWeb) {
      try {
        return await _deriveKeyWeb(
          password: password,
          salt: salt,
          iterations: iterationCount,
          keyLength: desiredKeyLength,
          algorithm: algorithm,
        );
      } on Exception catch (e, stackTrace) {
        developer.log(
          'Web PBKDF2 failed, falling back to Dart implementation.',
          name: 'pig_app.auth',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    return _deriveKeyDart(
      password: password,
      salt: salt,
      blockLength: blockLength,
      iterations: iterationCount,
      keyLength: desiredKeyLength,
      algorithm: algorithm,
    );
  }

  static String hmacHex(Uint8List key, String message) {
    final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
    final digest = hmac.process(Uint8List.fromList(utf8.encode(message)));
    return _bytesToHex(digest);
  }

  static crypto.MacAlgorithm _macForAlgorithm(String algorithm) {
    switch (algorithm) {
      case 'pbkdf2-sha256':
        return crypto.Hmac.sha256();
      case 'pcks':
        return crypto.Hmac.sha512();
    }
    throw ArgumentError('Unsupported auth algorithm: $algorithm');
  }

  static Future<Uint8List> _deriveKeyWeb({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
    required String algorithm,
  }) async {
    final macAlgorithm = _macForAlgorithm(algorithm);
    final pbkdf2 = crypto.Pbkdf2(
      macAlgorithm: macAlgorithm,
      iterations: iterations,
      bits: keyLength * 8,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  static Uint8List _deriveKeyDart({
    required String password,
    required Uint8List salt,
    required int blockLength,
    required int iterations,
    required int keyLength,
    required String algorithm,
  }) {
    final digest = _digestForAlgorithm(algorithm);
    final pbkdf2 = PBKDF2KeyDerivator(HMac(digest, blockLength))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Digest _digestForAlgorithm(String algorithm) {
    switch (algorithm) {
      case 'pbkdf2-sha256':
        return SHA256Digest();
      case 'pcks':
        return SHA512Digest();
    }
    throw ArgumentError('Unsupported auth algorithm: $algorithm');
  }

  static String _bytesToHex(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
