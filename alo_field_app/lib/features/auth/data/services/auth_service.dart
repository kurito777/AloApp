import '../models/technician.dart';
import 'employee_service.dart';

/// Servicio de autenticación del técnico.
///
/// Hoy resuelve la identidad contra la tabla maestra OHEM (vía [EmployeeService]).
/// Cuando exista el flujo de verificación por correo (OTP), este servicio
/// coordinará el envío/validación del código antes de confirmar la sesión.
class AuthService {
  AuthService(this._employeeService);

  final EmployeeService _employeeService;

  /// Resuelve el técnico a partir de su correo. `null` si no está registrado.
  ///
  /// Además de la identidad (OHEM), enriquece con el taller y rol de supervisor
  /// desde OUSR, necesarios para filtrar las órdenes del dashboard.
  Future<Technician?> resolveByEmail(String email) async {
    final tech = await _employeeService.findByEmail(email);
    if (tech == null) return null;
    return _employeeService.enrichWithUser(tech);
  }
}
