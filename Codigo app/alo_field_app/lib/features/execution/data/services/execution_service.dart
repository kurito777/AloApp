import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/config/sap_config.dart';
import '../../../dashboard/data/services/sap_auth_service.dart';
import '../models/service_call_item.dart';

/// Servicio de "Ejecución": llamadas de servicio (OSCL) del técnico.
///
/// Filtra por `TechnicianCode` (EmployeeID) y/o `AssigneeCode` (usuario OUSR),
/// separando abiertas (Status -3) e historial (cerradas).
class ExecutionService {
  ExecutionService({required SapAuthService authService, Dio? dio})
      : _auth = authService,
        _dio = dio ?? _buildDio();

  final SapAuthService _auth;
  final Dio _dio;

  static const _select =
      'ServiceCallID,Subject,Description,Status,Priority,CustomerCode,'
      'CustomerName,ItemCode,ManufacturerSerialNum,InternalSerialNum,'
      'CreationDate,ClosingDate,TechnicianCode,AssigneeCode';

  /// Trae las llamadas de servicio del técnico.
  ///
  /// [empId] = OHEM.EmployeeID (TechnicianCode); [userId] = OUSR (AssigneeCode).
  /// [onlyOpen] true = Pendientes (Status -3); false = Historial (cerradas).
  Future<List<ServiceCallItem>> fetchMyServiceCalls({
    required String empId,
    String? userId,
    required bool onlyOpen,
    int top = SapConfig.defaultPageSize,
    int skip = 0,
  }) async {
    // Asignado a mí: por técnico (empleado) o por usuario responsable.
    final assigned = <String>[];
    if (empId.isNotEmpty) assigned.add('TechnicianCode eq $empId');
    if (userId != null && userId.isNotEmpty) {
      assigned.add('AssigneeCode eq $userId');
    }
    final assignedFilter =
        assigned.isEmpty ? '' : '(${assigned.join(' or ')})';

    final statusFilter = onlyOpen ? 'Status eq -3' : 'Status ne -3';
    final filter = [assignedFilter, statusFilter]
        .where((s) => s.isNotEmpty)
        .join(' and ');

    dev.log('[ExecutionService] filter="$filter" top=$top skip=$skip');

    final headers = await _auth.getAuthHeaders();
    final response = await _dio.get(
      SapConfig.serviceCallsEndpoint,
      queryParameters: <String, dynamic>{
        r'$filter': filter,
        r'$select': _select,
        r'$orderby': 'ServiceCallID desc',
        r'$top': top,
        r'$skip': skip,
      },
      options: Options(
        headers: {...headers, 'Prefer': 'odata.maxpagesize=$top'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (response.statusCode == 401) {
      _auth.invalidateSession();
      throw const SapAuthException('Sesión SAP expirada.');
    }
    if (response.statusCode != 200) {
      final msg = response.data?['error']?['message']?['value'] ??
          'Error HTTP ${response.statusCode}';
      throw SapServiceException(msg, statusCode: response.statusCode);
    }

    final body = response.data;
    if (body is Map<String, dynamic> && body['value'] is List) {
      return (body['value'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ServiceCallItem.fromJson)
          .toList();
    }
    return const [];
  }

  static Dio _buildDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: SapConfig.connectTimeout,
      receiveTimeout: SapConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
    // Cert validado por defecto; solo se omite con SAP_VERIFY_TLS=false.
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
