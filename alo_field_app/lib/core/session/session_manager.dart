import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/models/technician.dart';

/// Gestiona la sesión del técnico autenticado.
///
/// Mantiene la identidad en memoria para acceso síncrono y la persiste de forma
/// segura en [FlutterSecureStorage] para sobrevivir reinicios de la app.
///
/// NOTA: aquí se guardará también el JWT/token cuando exista el flujo de
/// verificación por correo (OTP). Hoy solo persiste la identidad del técnico.
class SessionManager {
  SessionManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kTechnicianKey = 'auth.technician';

  Technician? _current;

  Technician? get currentTechnician => _current;

  bool get isAuthenticated => _current != null;

  /// Código SAP del técnico (EmployeeID de OHEM). Null si no hay sesión.
  String? get technicianCode => _current?.code;

  /// Taller/faena del técnico (OUSR.U_VID_Taller). Filtra las OMs del dashboard.
  String? get technicianTaller => _current?.taller;

  /// Usuario SAP del técnico (OUSR.InternalKey). Para filtrar por AssigneeCode.
  String? get applicationUserId => _current?.applicationUserId;

  /// Carga la sesión persistida al arrancar la app. Idempotente.
  Future<Technician?> restore() async {
    if (_current != null) return _current;
    try {
      final raw = await _storage.read(key: _kTechnicianKey);
      if (raw != null && raw.isNotEmpty) {
        _current = Technician.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        dev.log('[SessionManager] Sesión restaurada: ${_current!.code}');
      }
    } catch (e) {
      dev.log('[SessionManager] No se pudo restaurar sesión: $e');
      _current = null;
    }
    return _current;
  }

  /// Persiste la identidad del técnico autenticado.
  Future<void> save(Technician technician) async {
    _current = technician;
    await _storage.write(
      key: _kTechnicianKey,
      value: jsonEncode(technician.toJson()),
    );
    dev.log('[SessionManager] Sesión guardada: ${technician.code}');
  }

  /// Limpia toda la información sensible local (logout).
  Future<void> clear() async {
    _current = null;
    await _storage.delete(key: _kTechnicianKey);
    dev.log('[SessionManager] Sesión limpiada.');
  }
}
