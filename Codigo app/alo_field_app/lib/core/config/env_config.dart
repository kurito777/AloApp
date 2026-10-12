import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? '';

  static String get sapBaseUrl =>
      dotenv.env['SAP_BASE_URL'] ?? '';

  static String get environment =>
      dotenv.env['ENVIRONMENT'] ?? '';

  /// API key de Google Maps (Embed API para el mapa en web).
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
}