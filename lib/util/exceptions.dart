import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

import 'auth_store.dart';

class IrrigationAppException implements Exception {
  String message;

  IrrigationAppException(this.message);

  @override
  String toString() => message;
}

class BackupException extends IrrigationAppException {
  BackupException(super.message);
}

class InvoiceException extends IrrigationAppException {
  InvoiceException(super.message);
}

class XeroException extends IrrigationAppException {
  XeroException(super.message);
}

class InvalidPathException extends IrrigationAppException {
  InvalidPathException(super.message);
}

class NetworkException extends IrrigationAppException {
  // Either a Response or another Exception
  final Response? _response;
  final Exception? _cause;

  String? action;

  NetworkException(Response response, {this.action})
    : _response = response,
      _cause = null,
      super(response.body) {
    _handleInvalidToken(response);
  }

  NetworkException.fromException(Exception cause, {this.action})
    : _cause = cause,
      _response = null,
      super(cause.toString());

  @override
  String get message => _cause != null
      ? 'NetworkException: $_cause $action'
      : '${_response!.statusCode} ${_response.body} $action';
}

void _handleInvalidToken(Response response) {
  if (!_isInvalidTokenResponse(response)) {
    return;
  }
  final message = _extractErrorMessage(response) ??
      'Your session expired. Please log in again.';
  unawaited(AuthStore.handleInvalidToken(message));
}

bool _isInvalidTokenResponse(Response response) {
  if (response.statusCode != 401 && response.statusCode != 403) {
    return false;
  }
  final message = _extractErrorMessage(response);
  if (message == null || message.isEmpty) {
    return false;
  }
  final lower = message.toLowerCase();
  return lower.contains('token') &&
      (lower.contains('invalid') || lower.contains('expired'));
}

String? _extractErrorMessage(Response response) {
  try {
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String) {
        return error;
      }
    }
  } on Exception {
    return null;
  }
  return null;
}
