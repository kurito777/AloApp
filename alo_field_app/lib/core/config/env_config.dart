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

  /// Webhook n8n que registra el OTP en Google Sheets. Vacío = modo dev
  /// (el código se imprime en consola en vez de enviarse).
  static String get otpWebhookUrl => dotenv.env['OTP_WEBHOOK_URL'] ?? '';

  /// Correos de PRUEBA que saltan la validación OHEM y van directo al OTP
  /// (dev). Vacío en producción. Separados por coma.
  static List<String> get otpDevEmails => (dotenv.env['OTP_DEV_EMAILS'] ?? '')
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();
}