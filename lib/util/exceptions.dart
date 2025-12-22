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
  Response response;

  String? action;

  NetworkException(this.response, {this.action}) : super(response.body);

  @override
  String get message => '${response.statusCode} ${response.body} $action';
}
