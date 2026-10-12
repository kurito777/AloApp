class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class AuthException extends AppException {
  AuthException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class ServerException extends AppException {
  ServerException(super.message);
}

class CacheException extends AppException {
  CacheException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}

/// El gate global de escritura contra SAP está cerrado.
///
/// Se lanza cuando se intenta un PATCH/POST y `SAP_WRITE_ENABLED` no es `true`.
/// Protege la base de datos de SAP de escrituras accidentales en pruebas.
class SapWriteGateException extends AppException {
  final String udo;
  SapWriteGateException(this.udo)
      : super(
          'Escritura a SAP bloqueada (gate cerrado) para "$udo". '
          'Habilita SAP_WRITE_ENABLED=true en .env para permitir cambios reales.',
        );
}

/// Se intentó escribir sobre una entidad/UDO no permitido por la app.
class SapWriteNotAllowedException extends AppException {
  final String udo;
  SapWriteNotAllowedException(this.udo)
      : super('La app no tiene permitido escribir sobre "$udo".');
}
