import 'package:http/http.dart';

class IrrigationAppException implements Exception {
  IrrigationAppException(this.message);

  String message;

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
  NetworkException(this.response, {this.action}) : super(response.body);

  Response response;

  String? action;

  @override
  String get message => '${response.statusCode} ${response.body} $action';
}
