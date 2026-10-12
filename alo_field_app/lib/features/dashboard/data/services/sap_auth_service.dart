import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/config/sap_config.dart';

/// Resultado de una sesión SAP B1 activa.
class SapSession {
  final String sessionId;
  final String? routeId;
  final DateTime expiresAt;

  const SapSession({
    required this.sessionId,
    this.routeId,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get needsRefresh =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 2)));

  /// Headers de cookie necesarios para cada request autenticado.
  Map<String, String> get cookieHeaders {
    final cookie = 'B1SESSION=$sessionId'
        '${routeId != null ? '; ROUTEID=$routeId' : ''}';
    return {'Cookie': cookie};
  }
}

/// Servicio de autenticación contra SAP B1 Service Layer.
///
/// Gestiona login, logout y renovación automática de sesión.
/// SAP B1 Service Layer usa cookies (B1SESSION + ROUTEID) para autenticación.
class SapAuthService {
  SapAuthService({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;
  SapSession? _currentSession;

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Autentica contra SAP B1 Service Layer y retorna una [SapSession].
  ///
  /// Lanza [SapAuthException] si las credenciales son inválidas.
  /// Lanza [SapNetworkException] si hay problemas de conectividad.
  Future<SapSession> login({
    String? companyDb,
    String? userName,
    String? password,
  }) async {
    final body = {
      'CompanyDB': companyDb ?? SapConfig.company,
      'UserName': userName ?? SapConfig.serviceUser,
      'Password': password ?? SapConfig.servicePassword,
      'Language': 25,
    };

    dev.log('[SAP Auth] Iniciando login para ${body['UserName']}@${body['CompanyDB']}');

    try {
      final response = await _dio.post(
        SapConfig.loginEndpoint,
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (response.statusCode == 200) {
        final session = _extractSession(response);
        _currentSession = session;
        dev.log('[SAP Auth] Login exitoso. Sesión válida hasta ${session.expiresAt}');
        return session;
      } else if (response.statusCode == 401) {
        throw SapAuthException(
          'Credenciales inválidas. Verifica SAP_SERVICE_USER y SAP_SERVICE_PASSWORD.',
        );
      } else {
        final errMsg = response.data?['error']?['message']?['value'] ??
            'Error desconocido (HTTP ${response.statusCode})';
        throw SapAuthException('Login fallido: $errMsg');
      }
    } on DioException catch (e) {
      dev.log('[SAP Auth] DioException en login: ${e.type} - ${e.message}');
      throw _mapDioException(e);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Cierra la sesión SAP activa.
  Future<void> logout() async {
    if (_currentSession == null || _currentSession!.isExpired) {
      _currentSession = null;
      return;
    }

    try {
      await _dio.post(
        SapConfig.logoutEndpoint,
        options: Options(
          headers: _currentSession!.cookieHeaders,
          validateStatus: (s) => true,
        ),
      );
      dev.log('[SAP Auth] Logout exitoso.');
    } catch (_) {
      // El logout falla silenciosamente; la sesión expirará de todas formas.
    } finally {
      _currentSession = null;
    }
  }

  // ── Sesión activa ──────────────────────────────────────────────────────────

  /// Retorna la sesión activa, refrescándola si está próxima a expirar.
  ///
  /// Si no hay sesión activa, realiza login automático con credenciales del .env.
  Future<SapSession> getActiveSession() async {
    if (_currentSession == null || _currentSession!.isExpired) {
      dev.log('[SAP Auth] Sesión nula o expirada. Realizando login automático.');
      return login();
    }

    if (_currentSession!.needsRefresh) {
      dev.log('[SAP Auth] Sesión próxima a expirar. Refrescando.');
      try {
        return await login();
      } catch (e) {
        // Si el refresh falla pero la sesión aún es válida, la reutilizamos.
        if (!_currentSession!.isExpired) return _currentSession!;
        rethrow;
      }
    }

    return _currentSession!;
  }

  /// Retorna los headers de cookie para la sesión activa (auto-login si necesario).
  Future<Map<String, String>> getAuthHeaders() async {
    final session = await getActiveSession();
    return session.cookieHeaders;
  }

  /// Invalida la sesión en caché (útil tras errores 401 en requests).
  void invalidateSession() {
    dev.log('[SAP Auth] Sesión invalidada manualmente.');
    _currentSession = null;
  }

  bool get hasActiveSession =>
      _currentSession != null && !_currentSession!.isExpired;

  // ── Helpers privados ───────────────────────────────────────────────────────

  SapSession _extractSession(Response response) {
    // SAP retorna SessionId en el body y el ROUTEID en el header Set-Cookie.
    final data = response.data as Map<String, dynamic>? ?? {};
    final sessionId = data['SessionId'] as String? ?? '';

    if (sessionId.isEmpty) {
      throw SapAuthException(
        'SAP no retornó SessionId. Respuesta: ${response.data}',
      );
    }

    // Extraer ROUTEID del header Set-Cookie si está presente.
    String? routeId;
    final rawCookies = response.headers['set-cookie'];
    if (rawCookies != null) {
      for (final cookie in rawCookies) {
        final match = RegExp(r'ROUTEID=([^;]+)').firstMatch(cookie);
        if (match != null) {
          routeId = match.group(1);
          break;
        }
      }
    }

    return SapSession(
      sessionId: sessionId,
      routeId: routeId,
      expiresAt: DateTime.now().add(SapConfig.sessionRefreshThreshold),
    );
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return SapNetworkException(
          'Timeout al conectar con SAP. Verifica que SAP_BASE_URL sea accesible.',
        );
      case DioExceptionType.connectionError:
        return SapNetworkException(
          'No se pudo conectar a SAP B1. '
          'Verifica la URL: ${SapConfig.baseUrl} y conectividad de red.',
        );
      case DioExceptionType.badCertificate:
        return SapNetworkException(
          'Error de certificado SSL con SAP. '
          'Si usas certificado auto-firmado, configura badCertificateCallback.',
        );
      default:
        return SapNetworkException('Error de red: ${e.message}');
    }
  }

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: SapConfig.connectTimeout,
        receiveTimeout: SapConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // SAP B1 puede usar certificados auto-firmados en entornos on-premise.
    // Por defecto se VALIDA el certificado; solo se omite si SAP_VERIFY_TLS=false
    // (gate explícito de .env para dev/on-premise). Nunca en producción.
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

// ── Excepciones ────────────────────────────────────────────────────────────────

class SapAuthException implements Exception {
  final String message;
  const SapAuthException(this.message);

  @override
  String toString() => 'SapAuthException: $message';
}

class SapNetworkException implements Exception {
  final String message;
  const SapNetworkException(this.message);

  @override
  String toString() => 'SapNetworkException: $message';
}

class SapServiceException implements Exception {
  final String message;
  final int? statusCode;

  const SapServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'SapServiceException($statusCode): $message';
}