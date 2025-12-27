import '../util/auth_store.dart';

Map<String, String> jsonHeaders() {
  final headers = <String, String>{'Content-Type': 'application/json'};
  final token = AuthStore.token;
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}
