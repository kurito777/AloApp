import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/config/sap_config.dart';
import '../../../dashboard/data/services/sap_auth_service.dart';
import '../models/technician.dart';

/// Consulta la tabla maestra de empleados (OHEM / `EmployeesInfo`) en SAP B1
/// para resolver la identidad del técnico a partir de su correo corporativo.
///
/// Delega la autenticación de sesión SAP a [SapAuthService].
class EmployeeService {
  EmployeeService({
    required SapAuthService authService,
    Dio? dio,
  })  : _auth = authService,
        _dio = dio ?? _buildDio();

  final SapAuthService _auth;
  final Dio _dio;

  /// Campos mínimos a traer de OHEM para construir la identidad del técnico.
  static const _selectFields =
      'EmployeeID,FirstName,LastName,eMail,JobTitle,MobilePhone,'
      'HomePhone,OfficePhone,Department,Branch,Active,ApplicationUserID';

  /// Busca un técnico por correo en OHEM. Retorna `null` si no existe.
  ///
  /// Estrategia (este Service Layer NO soporta funciones case-insensitive como
  /// tolower/toupper/substringof, y `eq` es sensible a mayúsculas mientras que
  /// los correos en OHEM tienen casing inconsistente):
  ///   1. Intento exacto `eMail eq '<correo>'` (rápido, 1 request).
  ///   2. Fallback: escaneo paginado de OHEM comparando en minúsculas.
  ///
  /// Lanza [SapAuthException] / [SapNetworkException] / [SapServiceException].
  Future<Technician?> findByEmail(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) return null;
    final target = normalized.toLowerCase();

    dev.log('[EmployeeService] Buscando técnico por email="$normalized"');

    // 1) Intento exacto (rápido si el casing coincide con lo almacenado).
    // OHEM puede tener duplicados con el mismo correo (activo vs "No Usar"):
    // se traen todas las coincidencias y se prefiere la activa.
    final escaped = normalized.replaceAll("'", "''");
    final exact = await _fetchPage(filter: "eMail eq '$escaped'", top: 20);
    final best1 = _pickBest(exact, target);
    if (best1 != null) {
      dev.log('[EmployeeService] Match exacto (activo=${best1['Active']}).');
      return Technician.fromEmployeesInfo(best1);
    }

    // 2) Fallback case-insensitive: escanear páginas y comparar en cliente
    // (este Service Layer no soporta tolower/toupper).
    const pageSize = 500;
    var skip = 0;
    final matches = <Map<String, dynamic>>[];
    while (true) {
      final rows = await _fetchPage(top: pageSize, skip: skip);
      if (rows.isEmpty) break;
      for (final row in rows) {
        if ((row['eMail'] ?? '').toString().trim().toLowerCase() == target) {
          matches.add(row);
        }
      }
      if (rows.length < pageSize) break; // última página
      skip += pageSize;
    }

    final best2 = _pickBest(matches, target);
    if (best2 != null) {
      dev.log('[EmployeeService] Match case-insensitive (activo=${best2['Active']}).');
      return Technician.fromEmployeesInfo(best2);
    }

    dev.log('[EmployeeService] Técnico no encontrado para "$normalized".');
    return null;
  }

  /// De las filas con correo == [targetLower], prefiere la que esté activa
  /// (Active == 'tYES'); si ninguna, retorna la primera. `null` si no hay.
  Map<String, dynamic>? _pickBest(
    List<Map<String, dynamic>> rows,
    String targetLower,
  ) {
    final ms = rows
        .where((r) =>
            (r['eMail'] ?? '').toString().trim().toLowerCase() == targetLower)
        .toList();
    if (ms.isEmpty) return null;
    ms.sort((a, b) {
      final aActive = a['Active']?.toString() == 'tYES' ? 0 : 1;
      final bActive = b['Active']?.toString() == 'tYES' ? 0 : 1;
      return aActive.compareTo(bActive);
    });
    return ms.first;
  }

  /// Enriquece al técnico con su taller (OUSR.U_VID_Taller) y si es supervisor
  /// (OUSR.U_VID_MTSup), enlazando por OHEM.ApplicationUserID → OUSR.InternalKey.
  ///
  /// Si no hay `applicationUserId` o no se encuentra el usuario, retorna el
  /// técnico sin taller (el dashboard lo tratará como dato faltante).
  Future<Technician> enrichWithUser(Technician tech) async {
    final appUserId = tech.applicationUserId;
    if (appUserId == null || appUserId.isEmpty) return tech;

    final headers = await _auth.getAuthHeaders();
    final response = await _dio.get(
      SapConfig.usersEndpoint,
      queryParameters: <String, dynamic>{
        r'$filter': 'InternalKey eq $appUserId',
        r'$select': 'InternalKey,UserCode,U_VID_Taller,U_VID_MTSup',
        r'$top': 1,
      },
      options: Options(
        headers: {...headers, 'Prefer': 'odata.maxpagesize=1'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (response.statusCode == 401) {
      _auth.invalidateSession();
      throw const SapAuthException('Sesión SAP expirada al buscar usuario.');
    }
    if (response.statusCode != 200) {
      // No es fatal para el login: seguimos sin taller.
      dev.log('[EmployeeService] OUSR HTTP ${response.statusCode}; sin taller.');
      return tech;
    }

    final value = (response.data is Map<String, dynamic>)
        ? response.data['value']
        : null;
    if (value is List && value.isNotEmpty && value.first is Map) {
      final row = value.first as Map;
      final taller = (row['U_VID_Taller'] ?? '').toString().trim();
      final isSup = (row['U_VID_MTSup'] ?? '').toString().trim().toUpperCase() == 'Y';
      dev.log('[EmployeeService] Taller=$taller supervisor=$isSup');
      return tech.withUser(
        taller: taller.isEmpty ? null : taller,
        isSupervisor: isSup,
      );
    }
    return tech;
  }

  /// Ejecuta un GET a EmployeesInfo y retorna las filas (`value`).
  Future<List<Map<String, dynamic>>> _fetchPage({
    String? filter,
    int top = 200,
    int skip = 0,
  }) async {
    final headers = await _auth.getAuthHeaders();
    final query = <String, dynamic>{
      r'$select': _selectFields,
      r'$top': top,
      r'$skip': skip,
    };
    if (filter != null) query[r'$filter'] = filter;

    final response = await _dio.get(
      SapConfig.employeesInfoEndpoint,
      queryParameters: query,
      options: Options(
        // Sin este header, el Service Layer limita cada página a 20 filas.
        headers: {...headers, 'Prefer': 'odata.maxpagesize=$top'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (response.statusCode == 401) {
      _auth.invalidateSession();
      throw const SapAuthException('Sesión SAP expirada al buscar empleado.');
    }
    if (response.statusCode != 200) {
      final errMsg = response.data?['error']?['message']?['value'] ??
          'Error HTTP ${response.statusCode}';
      throw SapServiceException(errMsg, statusCode: response.statusCode);
    }

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final value = body['value'];
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: SapConfig.connectTimeout,
        receiveTimeout: SapConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // SAP B1 on-premise puede usar certificados auto-firmados.
    // Cert validado por defecto (evita MITM); el bypass solo se activa con el
    // gate explícito SAP_VERIFY_TLS=false en .env (dev/on-premise).
    if (!kIsWeb && !SapConfig.verifyTls) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    return dio;
  }
}
