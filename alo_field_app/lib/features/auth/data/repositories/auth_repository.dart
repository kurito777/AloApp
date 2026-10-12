import '../../../dashboard/data/services/sap_auth_service.dart';
import '../models/technician.dart';
import '../services/auth_service.dart';

/// Repositorio de autenticación. Traduce las excepciones técnicas de SAP a
/// mensajes listos para mostrar en la UI mediante [AuthFailure].
class AuthRepository {
  AuthRepository(this._authService);

  final AuthService _authService;

  /// Autentica al técnico validando su correo contra la tabla maestra (OHEM).
  ///
  /// Retorna el [Technician] si el correo existe; `null` si no está registrado.
  /// Lanza [AuthFailure] ante errores de sesión, red o servidor SAP.
  Future<Technician?> login(String email) async {
    try {
      return await _authService.resolveByEmail(email);
    } on SapAuthException catch (e) {
      throw AuthFailure(
        'No se pudo validar con SAP: ${e.message}',
        isRetryable: true,
      );
    } on SapNetworkException catch (e) {
      throw AuthFailure(
        'Sin conexión con SAP. Verifica tu red.',
        isRetryable: true,
        detail: e.message,
      );
    } on SapServiceException catch (e) {
      throw AuthFailure(
        'Error del servidor SAP: ${e.message}',
        isRetryable: true,
      );
    } catch (e) {
      throw AuthFailure('Error inesperado al iniciar sesión.', detail: '$e');
    }
  }
}

/// Error de autenticación con mensaje listo para UI.
class AuthFailure implements Exception {
  final String message;
  final bool isRetryable;
  final String? detail;

  const AuthFailure(this.message, {this.isRetryable = false, this.detail});

  @override
  String toString() => 'AuthFailure: $message${detail != null ? ' ($detail)' : ''}';
}
