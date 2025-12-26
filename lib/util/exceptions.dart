import 'package:http/http.dart';

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
      super(response.body);

  NetworkException.fromException(Exception cause, {this.action})
    : _cause = cause,
      _response = null,
      super(cause.toString());

  @override
  String get message => _cause != null
      ? 'NetworkException: $_cause $action'
      : '${_response!.statusCode} ${_response.body} $action';
}
