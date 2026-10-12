import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/config/sap_config.dart';
import 'sap_auth_service.dart';

/// Servicio de acceso a datos del UDO VID_RTOV en SAP B1 Service Layer.
///
/// Responsabilidades:
/// - Consultar órdenes de taller con filtros OData
/// - Actualizar estado de una OT via PATCH
/// - Delegar autenticación a [SapAuthService]
class DashboardService {
  DashboardService({
    required SapAuthService authService,
    Dio? dio,
  })  : _auth = authService,
        _dio = dio ?? _buildDio();

  final SapAuthService _auth;
  final Dio _dio;

  // ── Consultar órdenes ──────────────────────────────────────────────────────

  /// Retorna lista de órdenes VID_RTOV (OT) para el técnico indicado.
  ///
  /// [technicianCode] filtra por U_TecnicoCode.
  /// [estados] lista de códigos SAP (P, EC, EA, EP, F, C); null = todos.
  /// [top] cantidad máxima de registros (paginación).
  /// [skip] offset para paginación.
  Future<List<Map<String, dynamic>>> fetchOrders({
    String? technicianCode,
    List<String>? estados,
    int top = SapConfig.defaultPageSize,
    int skip = 0,
  }) async {
    final filter = _buildFilter(
      technicianCode: technicianCode,
      estados: estados,
    );

    final queryParams = <String, dynamic>{
      r'$top': top,
      r'$skip': skip,
      r'$orderby': 'DocNum desc',
    };
    if (filter.isNotEmpty) queryParams[r'$filter'] = filter;

    dev.log('[DashboardService] fetchOrders filter="$filter" top=$top skip=$skip');

    return _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.get(
        SapConfig.udoListEndpoint(SapConfig.udoRtov),
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _parseListResponse(response);
    });
  }

  // ── Órdenes de Mantenimiento (OM) ─────────────────────────────────────────

  /// Retorna lista de órdenes VID_MTSOLREP (OM) para el técnico indicado.
  ///
  /// [technicianCode] filtra por U_TecnicoCode.
  /// [estados] lista de códigos SAP (P, EC, EA, EP, F, C); null = todos.
  /// [top] cantidad máxima de registros (paginación).
  /// [skip] offset para paginación.
  Future<List<Map<String, dynamic>>> fetchOMOrders({
    String? technicianCode,
    List<String>? estados,
    bool onlyOpen = true,
    int top = SapConfig.defaultPageSize,
    int skip = 0,
  }) async {
    final filter = _buildFilter(
      technicianCode: technicianCode,
      estados: estados,
      onlyOpen: onlyOpen,
    );

    final queryParams = <String, dynamic>{
      r'$top': top,
      r'$skip': skip,
      r'$orderby': 'DocNum desc',
    };
    if (filter.isNotEmpty) queryParams[r'$filter'] = filter;

    dev.log('[DashboardService] fetchOMOrders filter="$filter" top=$top skip=$skip');

    return _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.get(
        SapConfig.udoListEndpoint(SapConfig.udoMtsolrep),
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _parseListResponse(response);
    });
  }

  // ── Órdenes de Mantención (VID_MTOM) por taller ─────────────────────────────

  /// Retorna órdenes de mantención (VID_MTOM) del taller indicado.
  ///
  /// [taller] filtra por U_Taller (ej. "ANF-01"). Es el criterio MVP: el técnico
  /// ve las OMs de su taller/zona. Ordena por DocNum desc (más recientes primero)
  /// y pagina, porque un taller puede tener miles de OMs abiertas.
  Future<List<Map<String, dynamic>>> fetchMtomByTaller({
    required String taller,
    bool onlyOpen = true,
    int? sinceDays,
    int top = SapConfig.defaultPageSize,
    int skip = 0,
  }) async {
    final parts = <String>["U_Taller eq '${taller.replaceAll("'", "''")}'"];
    if (onlyOpen) parts.add("Status eq 'O'");

    // Ventana de fecha reciente (U_FecOrden ge fecha) para acotar el volumen.
    final days = sinceDays ?? SapConfig.dashboardRecentDays;
    if (days > 0) {
      final since = DateTime.now().subtract(Duration(days: days));
      final d = '${since.year}-'
          '${since.month.toString().padLeft(2, '0')}-'
          '${since.day.toString().padLeft(2, '0')}';
      parts.add("U_FecOrden ge '$d'");
    }

    final filter = parts.join(' and ');

    final queryParams = <String, dynamic>{
      r'$filter': filter,
      r'$top': top,
      r'$skip': skip,
      r'$orderby': 'DocNum desc',
    };

    dev.log('[DashboardService] fetchMtomByTaller filter="$filter" top=$top skip=$skip');

    return _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.get(
        SapConfig.udoListEndpoint(SapConfig.udoMtom),
        queryParameters: queryParams,
        options: Options(
          headers: {...headers, 'Prefer': 'odata.maxpagesize=$top'},
        ),
      );
      return _parseListResponse(response);
    });
  }

  // ── Órdenes de Mantención (VID_MTOM) por TÉCNICO ────────────────────────────

  /// Retorna las OM (VID_MTOM) cuyo responsable es el técnico [tecnicoCode].
  ///
  /// Relación verificada en SAP: `VID_MTOM.U_UsrRes` = `OHEM.EmployeeID` del
  /// técnico (distinto de `U_Superv` = supervisor). Cada OM trae embebida su
  /// colección de tareas `VID_MTOMTACollection` (sin $select para incluirlas).
  Future<List<Map<String, dynamic>>> fetchMtomByTecnico({
    required String tecnicoCode,
    bool onlyOpen = true,
    int top = SapConfig.defaultPageSize,
    int skip = 0,
  }) async {
    final code = tecnicoCode.replaceAll("'", "''");
    final parts = <String>["U_UsrRes eq '$code'"];
    if (onlyOpen) parts.add("Status eq 'O'");
    // Excluir OM Cerradas ('C') y Canceladas ('X'): SAP no permite editarlas
    // (TN AG_TN_VIDMTOM_OM) y no son accionables por el técnico.
    parts.add("U_Estado ne 'C'");
    parts.add("U_Estado ne 'X'");
    final filter = parts.join(' and ');

    final queryParams = <String, dynamic>{
      r'$filter': filter,
      r'$top': top,
      r'$skip': skip,
      r'$orderby': 'DocNum desc',
    };

    dev.log('[DashboardService] fetchMtomByTecnico filter="$filter" top=$top skip=$skip');

    return _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.get(
        SapConfig.udoListEndpoint(SapConfig.udoMtom),
        queryParameters: queryParams,
        options: Options(
          headers: {...headers, 'Prefer': 'odata.maxpagesize=$top'},
        ),
      );
      return _parseListResponse(response);
    });
  }

  /// Detalle completo de una OM (VID_MTOM) por DocEntry.
  Future<Map<String, dynamic>> fetchMtomDetail(int docEntry) async {
    dev.log('[DashboardService] fetchMtomDetail docEntry=$docEntry');
    return _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.get(
        SapConfig.udoEntryEndpoint(SapConfig.udoMtom, docEntry),
        options: Options(headers: headers),
      );
      return _parseSingleResponse(response, docEntry);
    });
  }

  // ── Escritura en la OM: tareas y materiales (VID_MTOM) ─────────────────────
  //
  // Mecánica verificada en SAP: el PATCH de una colección de UDO hace MERGE por
  // LineId (no reemplaza): basta enviar la línea nueva (se agrega) o la línea a
  // cambiar por su LineId (se actualiza). Protegido por el gate SAP_WRITE_ENABLED.

  /// Agrega una tarea a la OM (VID_MTOMTACollection). Estado inicial 'N'.
  Future<void> addOmTask(
    int docEntry, {
    required String name,
    String estado = 'N',
    String? tecnicoCode,
    String? tecnicoName,
  }) async {
    SapConfig.assertWritable(SapConfig.udoMtom);
    final line = <String, dynamic>{'U_Name': name, 'U_Estado': estado};
    if (tecnicoCode != null && tecnicoCode.isNotEmpty) {
      line['U_UsrResp'] = tecnicoCode;
    }
    if (tecnicoName != null && tecnicoName.isNotEmpty) {
      line['U_UsrRespN'] = tecnicoName;
    }
    await _patchMtom(docEntry, {
      'VID_MTOMTACollection': [line],
    });
  }

  /// Marca el avance de una tarea de la OM (U_Estado: 'N'/'P'/'T').
  Future<void> setOmTaskEstado(int docEntry, int lineId, String estado) async {
    SapConfig.assertWritable(SapConfig.udoMtom);
    await _patchMtom(docEntry, {
      'VID_MTOMTACollection': [
        {'LineId': lineId, 'U_Estado': estado},
      ],
    });
  }

  /// Agrega un material usado a la OM (VID_MTOMMACollection).
  Future<void> addOmMaterial(
    int docEntry, {
    required String itemName,
    required double cantidad,
    String? itemCode,
    String? um,
  }) async {
    SapConfig.assertWritable(SapConfig.udoMtom);
    final line = <String, dynamic>{
      'U_ItemName': itemName,
      'U_Cantidad': cantidad,
    };
    if (itemCode != null && itemCode.isNotEmpty) line['U_ItemCode'] = itemCode;
    if (um != null && um.isNotEmpty) line['U_UM'] = um;
    await _patchMtom(docEntry, {
      'VID_MTOMMACollection': [line],
    });
  }

  Future<void> _patchMtom(int docEntry, Map<String, dynamic> payload) async {
    dev.log('[DashboardService] _patchMtom docEntry=$docEntry payload=$payload');
    await _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.patch(
        SapConfig.udoEntryEndpoint(SapConfig.udoMtom, docEntry),
        data: payload,
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (response.statusCode == 401) {
        _auth.invalidateSession();
        throw SapAuthException('Sesión expirada al escribir en la OM.');
      }
      if (response.statusCode != 204 && response.statusCode != 200) {
        final err = response.data?['error']?['message']?['value'] ??
            'Error al escribir en la OM (HTTP ${response.statusCode})';
        throw SapServiceException(err, statusCode: response.statusCode);
      }
    });
  }

  // ── Detalle de una OT (Orden de Taller) ─────────────────────────────────────

  /// Retorna el detalle completo (incluyendo VID_RTOVDCollection) de una OT.
  Future<Map<String, dynamic>> fetchOrderDetail(int docEntry) async {
    dev.log('[DashboardService] fetchOrderDetail docEntry=$docEntry');

    return _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.get(
        SapConfig.udoEntryEndpoint(SapConfig.udoRtov, docEntry),
        options: Options(headers: headers),
      );
      return _parseSingleResponse(response, docEntry);
    });
  }

  // ── Detalle de una OM (Orden de Mantenimiento) ─────────────────────────────

  /// Retorna el detalle completo de una OM desde VID_MTSOLREP.
  Future<Map<String, dynamic>> fetchOMOrderDetail(int docEntry) async {
    dev.log('[DashboardService] fetchOMOrderDetail docEntry=$docEntry');

    return _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.get(
        SapConfig.udoEntryEndpoint(SapConfig.udoMtsolrep, docEntry),
        options: Options(headers: headers),
      );
      return _parseSingleResponse(response, docEntry);
    });
  }

  // ── Actualizar estado de una OT ────────────────────────────────────────────

  /// Actualiza campos de una OT via PATCH en SAP B1.
  ///
  /// [docEntry] es el identificador único de la OT en SAP.
  /// [payload] contiene solo los campos a modificar (ej: {'U_Estado': 'EC'}).
  Future<void> patchOrder(int docEntry, Map<String, dynamic> payload) async {
    dev.log('[DashboardService] patchOrder docEntry=$docEntry payload=$payload');

    // Gate de escritura + allowlist de entidades (defensa antes de tocar SAP).
    SapConfig.assertWritable(SapConfig.udoRtov);

    await _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.patch(
        SapConfig.udoEntryEndpoint(SapConfig.udoRtov, docEntry),
        data: payload,
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (response.statusCode == 401) {
        _auth.invalidateSession();
        throw SapAuthException('Sesión expirada. Reintentando login.');
      }

      if (response.statusCode != 204 && response.statusCode != 200) {
        final errMsg =
            response.data?['error']?['message']?['value'] ?? 'Error PATCH SAP';
        throw SapServiceException(errMsg, statusCode: response.statusCode);
      }
    });
  }

  // ── Actualizar estado de una OM ────────────────────────────────────────────

  /// Actualiza campos de una OM via PATCH en VID_MTSOLREP.
  ///
  /// [docEntry] es el identificador único de la OM en SAP.
  /// [payload] contiene solo los campos a modificar.
  Future<void> patchOMOrder(int docEntry, Map<String, dynamic> payload) async {
    dev.log('[DashboardService] patchOMOrder docEntry=$docEntry payload=$payload');

    // Gate de escritura + allowlist de entidades (defensa antes de tocar SAP).
    SapConfig.assertWritable(SapConfig.udoMtsolrep);

    await _executeWithRetry(() async {
      final headers = await _auth.getAuthHeaders();
      final response = await _dio.patch(
        SapConfig.udoEntryEndpoint(SapConfig.udoMtsolrep, docEntry),
        data: payload,
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (response.statusCode == 401) {
        _auth.invalidateSession();
        throw SapAuthException('Sesión expirada. Reintentando login.');
      }

      if (response.statusCode != 204 && response.statusCode != 200) {
        final errMsg =
            response.data?['error']?['message']?['value'] ?? 'Error PATCH SAP OM';
        throw SapServiceException(errMsg, statusCode: response.statusCode);
      }
    });
  }

  /// Conveniencia: actualiza solo el estado de una OT.
  Future<void> updateOrderStatus(int docEntry, String newEstado) =>
      patchOrder(docEntry, {'U_Estado': newEstado});

  /// Registra llegada del técnico con coordenadas GPS opcionales.
  Future<void> markArrived(
    int docEntry, {
    double? lat,
    double? lng,
  }) {
    final payload = <String, dynamic>{
      'U_Estado': 'EA',
      if (lat != null) 'U_LatLlegada': lat,
      if (lng != null) 'U_LngLlegada': lng,
      'U_FechaLlegada': DateTime.now().toIso8601String(),
    };
    return patchOrder(docEntry, payload);
  }

  /// Registra inicio de la OT (técnico en sitio, comenzando trabajo).
  Future<void> markStarted(int docEntry) => patchOrder(docEntry, {
        'U_Estado': 'EP',
        'U_FechaInicio': DateTime.now().toIso8601String(),
      });

  /// Finaliza la OT con solución y comentarios.
  Future<void> markFinished(
    int docEntry, {
    String? solucion,
    String? comentarios,
  }) {
    final payload = <String, dynamic>{
      'U_Estado': 'F',
      'U_FechaFin': DateTime.now().toIso8601String(),
      if (solucion != null) 'U_Solucion': solucion,
      if (comentarios != null) 'U_ComTecnico': comentarios,
    };
    return patchOrder(docEntry, payload);
  }

  // ── Helpers privados ───────────────────────────────────────────────────────

  String _buildFilter({
    String? technicianCode,
    List<String>? estados,
    bool onlyOpen = false,
  }) {
    final parts = <String>[];

    // Técnico responsable de la OM (VID_MTSOLREP.U_UsrResp).
    if (technicianCode != null && technicianCode.isNotEmpty) {
      parts.add("U_UsrResp eq '$technicianCode'");
    }

    // Solo órdenes abiertas (Status estándar del objeto SAP).
    if (onlyOpen) {
      parts.add("Status eq 'O'");
    }

    if (estados != null && estados.isNotEmpty) {
      if (estados.length == 1) {
        parts.add("U_Estado eq '${estados.first}'");
      } else {
        final estadoFilter =
            estados.map((e) => "U_Estado eq '$e'").join(' or ');
        parts.add('($estadoFilter)');
      }
    }

    return parts.join(' and ');
  }

  List<Map<String, dynamic>> _parseListResponse(Response response) {
    if (response.statusCode == 401) {
      _auth.invalidateSession();
      throw SapAuthException('Sesión expirada al obtener órdenes.');
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
    return [];
  }

  Map<String, dynamic> _parseSingleResponse(Response response, int docEntry) {
    if (response.statusCode == 401) {
      _auth.invalidateSession();
      throw SapAuthException('Sesión expirada al obtener detalle.');
    }
    if (response.statusCode == 404) {
      throw SapServiceException(
        'Orden $docEntry no encontrada en SAP.',
        statusCode: 404,
      );
    }
    if (response.statusCode != 200) {
      final errMsg = response.data?['error']?['message']?['value'] ??
          'Error HTTP ${response.statusCode}';
      throw SapServiceException(errMsg, statusCode: response.statusCode);
    }

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw SapServiceException('Respuesta SAP inválida para docEntry=$docEntry');
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() action) async {
    Exception? lastError;

    for (var attempt = 1; attempt <= SapConfig.maxRetries; attempt++) {
      try {
        return await action();
      } on SapAuthException catch (e) {
        // Sesión SAP expirada (401) a mitad de operación: invalidamos la sesión
        // en caché y reintentamos; el próximo getAuthHeaders() re-loguea solo.
        // Si tras los reintentos sigue fallando (p. ej. credenciales inválidas),
        // se propaga. Patrón de recuperación tomado del backend CRM.
        lastError = e;
        _auth.invalidateSession();
        dev.log('[DashboardService] Auth 401 en intento $attempt/${SapConfig.maxRetries}: $e');
        if (attempt < SapConfig.maxRetries) {
          await Future.delayed(SapConfig.retryDelay * attempt);
        } else {
          rethrow;
        }
      } on SapNetworkException catch (e) {
        lastError = e;
        dev.log('[DashboardService] Intento $attempt/${SapConfig.maxRetries} falló: $e');
        if (attempt < SapConfig.maxRetries) {
          await Future.delayed(
            SapConfig.retryDelay * attempt,
          );
        }
      } on DioException catch (e) {
        lastError = SapNetworkException('Error de red: ${e.message}');
        dev.log('[DashboardService] DioException en intento $attempt: ${e.type}');
        if (attempt < SapConfig.maxRetries &&
            _isRetryableError(e.type)) {
          await Future.delayed(SapConfig.retryDelay * attempt);
        } else {
          break;
        }
      }
    }

    throw lastError ?? SapNetworkException('Error desconocido tras reintentos.');
  }

  bool _isRetryableError(DioExceptionType type) {
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.connectionError;
  }

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: SapConfig.connectTimeout,
        receiveTimeout: SapConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Prefer': 'odata.maxpagesize=${SapConfig.defaultPageSize}',
        },
      ),
    );

    // SAP B1 puede usar certificados auto-firmados en entornos on-premise.
    // Por defecto se VALIDA el certificado; solo se omite si SAP_VERIFY_TLS=false.
    // Dio 5.x requiere IOHttpClientAdapter.createHttpClient (no onHttpClientCreate).
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
