import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/sap_config.dart';
import '../../features/dashboard/data/services/sap_auth_service.dart';

/// Un artículo del maestro OITM (para elegir materiales).
class CatalogItem {
  final String code;
  final String name;

  const CatalogItem({required this.code, required this.name});
}

/// Resuelve códigos de SAP a sus descripciones legibles (Departamentos,
/// Sucursales), consultando tablas maestras del Service Layer y cacheándolas
/// en memoria para no repetir llamadas. También busca artículos (OITM).
///
/// - Departamentos: `Departments` (ODPT) → Code/Name (ej. 13 = "TI").
/// - Sucursales:    `Branches`          → Code/Name (ej. -2 = "SANTIAGO").
///
/// Si la consulta falla, [departmentName]/[branchName] devuelven el código tal
/// cual (nunca rompen la UI).
class CatalogService {
  CatalogService({required SapAuthService authService, Dio? dio})
      : _auth = authService,
        _dio = dio ?? _buildDio();

  final SapAuthService _auth;
  final Dio _dio;

  Map<String, String>? _departments;
  Map<String, String>? _branches;

  /// Nombre del departamento para un código (ej. "13" → "TI").
  Future<String> departmentName(String? code) =>
      _resolve(code, () => _ensureDepartments());

  /// Nombre de la sucursal para un código (ej. "-2" → "SANTIAGO").
  Future<String> branchName(String? code) =>
      _resolve(code, () => _ensureBranches());

  /// Busca artículos (OITM) por nombre o código. La búsqueda es case-sensitive
  /// en SAP y los nombres están en MAYÚSCULAS, así que la query se pasa en
  /// mayúsculas. Solo artículos válidos (Valid='tYES'). Máx [top] resultados.
  Future<List<CatalogItem>> searchItems(String query, {int top = 25}) async {
    final q = query.trim().toUpperCase().replaceAll("'", "''");
    if (q.length < 2) return const [];
    final filter =
        "(contains(ItemName,'$q') or contains(ItemCode,'$q')) and Valid eq 'tYES'";
    final headers = await _auth.getAuthHeaders();
    final response = await _dio.get(
      SapConfig.itemsEndpoint,
      queryParameters: <String, dynamic>{
        r'$filter': filter,
        r'$select': 'ItemCode,ItemName',
        r'$top': top,
        r'$orderby': 'ItemName',
      },
      options: Options(
        headers: {...headers, 'Prefer': 'odata.maxpagesize=$top'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (response.statusCode == 401) {
      _auth.invalidateSession();
      throw const SapAuthException('Sesión SAP expirada al buscar artículos.');
    }
    if (response.statusCode != 200) {
      throw SapServiceException(
        'Error HTTP ${response.statusCode} al buscar artículos',
        statusCode: response.statusCode,
      );
    }

    final out = <CatalogItem>[];
    final value = (response.data is Map<String, dynamic>)
        ? response.data['value']
        : null;
    if (value is List) {
      for (final row in value) {
        if (row is Map<String, dynamic>) {
          final code = row['ItemCode']?.toString().trim();
          final name = row['ItemName']?.toString().trim();
          if (code != null && code.isNotEmpty) {
            out.add(CatalogItem(code: code, name: name ?? code));
          }
        }
      }
    }
    return out;
  }

  // ── Interno ─────────────────────────────────────────────────────────────────

  Future<String> _resolve(
    String? code,
    Future<Map<String, String>> Function() loader,
  ) async {
    final key = code?.trim();
    if (key == null || key.isEmpty) return '—';
    try {
      final map = await loader();
      return map[key] ?? map[_normalizeInt(key)] ?? key;
    } catch (e) {
      dev.log('[CatalogService] No se pudo resolver "$key": $e');
      return key;
    }
  }

  /// Normaliza "13.0" → "13" por si el código viene con decimales.
  String _normalizeInt(String key) {
    final d = double.tryParse(key);
    if (d == null) return key;
    return d.toStringAsFixed(0);
  }

  Future<Map<String, String>> _ensureDepartments() async {
    return _departments ??=
        await _fetchCatalog(SapConfig.departmentsEndpoint);
  }

  Future<Map<String, String>> _ensureBranches() async {
    return _branches ??= await _fetchCatalog(SapConfig.branchesEndpoint);
  }

  Future<Map<String, String>> _fetchCatalog(String endpoint) async {
    final headers = await _auth.getAuthHeaders();
    final response = await _dio.get(
      endpoint,
      queryParameters: <String, dynamic>{r'$select': 'Code,Name'},
      options: Options(
        headers: {...headers, 'Prefer': 'odata.maxpagesize=200'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (response.statusCode == 401) {
      _auth.invalidateSession();
      throw const SapAuthException('Sesión SAP expirada al cargar catálogo.');
    }
    if (response.statusCode != 200) {
      throw SapServiceException(
        'Error HTTP ${response.statusCode} al cargar $endpoint',
        statusCode: response.statusCode,
      );
    }

    final map = <String, String>{};
    final value = (response.data is Map<String, dynamic>)
        ? response.data['value']
        : null;
    if (value is List) {
      for (final row in value) {
        if (row is Map<String, dynamic>) {
          final code = row['Code']?.toString().trim();
          final name = row['Name']?.toString().trim();
          if (code != null && code.isNotEmpty && name != null && name.isNotEmpty) {
            map[code] = name;
          }
        }
      }
    }
    return map;
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
