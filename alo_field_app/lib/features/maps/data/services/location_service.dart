import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/config/sap_config.dart';
import '../../../dashboard/data/services/sap_auth_service.dart';
import '../models/obra_location.dart';

/// Resuelve la ubicación (obra) de un equipo de mantención en SAP B1.
///
/// Cadena: `VID_MTEQUIPOS` (por Code == equipo) → `U_ContratoVenta`
/// → `VID_RTOV` (por DocNum) → `U_DestAddr` / `U_Dest` / `U_CardName`.
class LocationService {
  LocationService({required SapAuthService authService, Dio? dio})
      : _auth = authService,
        _dio = dio ?? _buildDio();

  final SapAuthService _auth;
  final Dio _dio;

  /// Resuelve la ubicación operacional del equipo.
  ///
  /// Prioridad (regla de negocio):
  ///  1. OBRA — contrato de arriendo de la OM ([docNumRtov]) → `VID_RTOV`.
  ///  2. TALLER — dirección real de la bodega del taller ([tallerCode] →
  ///     `VID_MTTALLER.U_WhsCode` → `Warehouses`).
  ///
  /// NOTA: no se usa `VID_MTEQUIPOS.U_ContratoVenta` (maestro desactualizado);
  /// el contrato vigente para el trabajo lo aporta la OM en `U_DocNum_RTOV`.
  Future<ObraLocation?> resolveObra(
    String equipoCode, {
    String? equipoName,
    String? docNumRtov,
    String? tallerCode,
  }) async {
    final code = equipoCode.trim();
    dev.log('[LocationService] resolveObra equipo="$code" rtov="$docNumRtov" taller="$tallerCode"');

    // 1) OBRA: contrato de arriendo referenciado por la OM.
    final rtov = (docNumRtov ?? '').trim();
    if (rtov.isNotEmpty && rtov != '0') {
      final ov = await _getOne(
        SapConfig.udoListEndpoint(SapConfig.udoRtov),
        filter: 'DocNum eq $rtov',
        select: 'DocNum,U_Dest,U_DestAddr,U_CardName,U_Estado',
      );
      final addr = ov == null ? null : _nz(ov['U_DestAddr']);
      if (addr != null) {
        return ObraLocation(
          equipoCode: code,
          equipoName: equipoName,
          type: LocationType.obra,
          contractNum: rtov,
          siteName: _nz(ov!['U_Dest']),
          clientName: _nz(ov['U_CardName']),
          address: addr,
        );
      }
    }

    // 2) TALLER: dirección real desde la bodega (OWHS).
    if (tallerCode != null && tallerCode.trim().isNotEmpty) {
      final tal = await _getOne(
        SapConfig.udoListEndpoint(SapConfig.udoMttaller),
        filter: "Code eq '${tallerCode.replaceAll("'", "''")}'",
        select: 'Code,Name,U_WhsCode',
      );
      String? whName;
      String? street;
      String? city;
      final whCode = tal == null ? null : _nz(tal['U_WhsCode']);
      if (whCode != null) {
        final wh = await _getOne(
          SapConfig.warehousesEndpoint,
          filter: "WarehouseCode eq '${whCode.replaceAll("'", "''")}'",
          select: 'WarehouseCode,WarehouseName,Street,City',
        );
        if (wh != null) {
          whName = _nz(wh['WarehouseName']);
          street = _nz(wh['Street']);
          city = _nz(wh['City']);
        }
      }

      final tallerName = tal == null ? null : _nz(tal['Name']);
      final ciudad = city ?? SapConfig.tallerCityName(tallerCode);
      final address = [street, ciudad].where((s) => s != null && s.isNotEmpty).join(', ');

      return ObraLocation(
        equipoCode: code,
        equipoName: equipoName,
        type: LocationType.taller,
        siteName: 'Taller ${tallerName ?? ciudad}',
        clientName: whName,
        address: address.isEmpty ? ciudad : address,
        ciudad: ciudad,
      );
    }

    // 3) Sin datos suficientes.
    return ObraLocation(
      equipoCode: code,
      equipoName: equipoName,
      type: LocationType.desconocida,
    );
  }

  Future<Map<String, dynamic>?> _getOne(
    String endpoint, {
    required String filter,
    required String select,
  }) async {
    final headers = await _auth.getAuthHeaders();
    final response = await _dio.get(
      endpoint,
      queryParameters: <String, dynamic>{
        r'$filter': filter,
        r'$select': select,
        r'$top': 1,
      },
      options: Options(
        headers: {...headers, 'Prefer': 'odata.maxpagesize=1'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    if (response.statusCode == 401) {
      _auth.invalidateSession();
      throw const SapAuthException('Sesión SAP expirada al resolver obra.');
    }
    if (response.statusCode != 200) {
      final msg = response.data?['error']?['message']?['value'] ??
          'Error HTTP ${response.statusCode}';
      throw SapServiceException(msg, statusCode: response.statusCode);
    }

    final value = (response.data is Map<String, dynamic>)
        ? response.data['value']
        : null;
    if (value is List && value.isNotEmpty && value.first is Map<String, dynamic>) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }

  static String? _nz(dynamic v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
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
