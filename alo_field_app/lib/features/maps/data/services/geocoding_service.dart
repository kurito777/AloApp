import 'dart:developer' as dev;

import 'package:dio/dio.dart';

/// Resultado de geocodificación: coordenadas + comuna/ciudad estructuradas.
class GeoResult {
  final double lat;
  final double lng;
  final String? comuna;
  final String? ciudad;
  final String? displayName;

  const GeoResult({
    required this.lat,
    required this.lng,
    this.comuna,
    this.ciudad,
    this.displayName,
  });
}

/// Geocodificación gratuita con Nominatim (OpenStreetMap) — sin API key ni
/// facturación. Convierte una dirección de texto en coordenadas y devuelve
/// comuna/ciudad (que SAP no almacena).
class GeocodingService {
  GeocodingService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _endpoint = 'https://nominatim.openstreetmap.org/search';

  Future<GeoResult?> geocode(String address) async {
    final q = address.trim();
    if (q.isEmpty) return null;

    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {
          'q': q,
          'format': 'json',
          'addressdetails': 1,
          'limit': 1,
          'countrycodes': 'cl',
        },
        options: Options(
          headers: {'User-Agent': 'ALOFieldApp/1.0 (soporte@alo-group.com)'},
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final data = response.data;
      if (data is List && data.isNotEmpty && data.first is Map) {
        final first = data.first as Map;
        final lat = double.tryParse('${first['lat']}');
        final lng = double.tryParse('${first['lon']}');
        if (lat == null || lng == null) return null;

        final addr = first['address'];
        String? comuna;
        String? ciudad;
        if (addr is Map) {
          comuna = _s(addr['suburb']) ??
              _s(addr['city_district']) ??
              _s(addr['town']) ??
              _s(addr['village']) ??
              _s(addr['municipality']);
          ciudad = _s(addr['city']) ??
              _s(addr['town']) ??
              _s(addr['county']) ??
              _s(addr['state']);
        }
        return GeoResult(
          lat: lat,
          lng: lng,
          comuna: comuna,
          ciudad: ciudad,
          displayName: _s(first['display_name']),
        );
      }
    } catch (e) {
      dev.log('[GeocodingService] Error geocodificando "$q": $e');
    }
    return null;
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }
}
