import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class AuthCrypto {
  static Uint8List deriveKey({
    required String password,
    required String saltBase64,
    required List<int> params,
    required String algorithm,
  }) {
    if (params.length < 3) {
      throw ArgumentError('PBKDF2 params must include 3 values.');
    }
    final blockLength = params[0];
    final iterationCount = params[1];
    final desiredKeyLength = params[2];
    final salt = base64.decode(saltBase64);
    final digest = _digestForAlgorithm(algorithm);
    final pbkdf2 = PBKDF2KeyDerivator(HMac(digest, blockLength))
      ..init(Pbkdf2Parameters(salt, iterationCount, desiredKeyLength));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  static String hmacHex(Uint8List key, String message) {
    final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
    final digest = hmac.process(Uint8List.fromList(utf8.encode(message)));
    return _bytesToHex(digest);
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
