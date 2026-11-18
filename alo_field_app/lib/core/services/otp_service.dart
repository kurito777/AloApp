import 'dart:developer' as dev;
import 'dart:math';

import 'package:dio/dio.dart';

import '../config/env_config.dart';

enum OtpResult { ok, invalid, expired, tooMany, noCode }

/// OTP de login. El código se genera y verifica en el cliente; se envía a un
/// webhook n8n que lo registra en Google Sheets (para ver el código en pruebas
/// sin entrar al correo). Estado en memoria (el código nunca se persiste).
///
/// ponytail: verificación local (no server-side). Suficiente para el flujo de
/// pruebas pedido; para OTP a prueba de clientes, mover verify a n8n.
class OtpService {
  OtpService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const Duration ttl = Duration(minutes: 5);
  static const int maxAttempts = 5;

  String? _code;
  DateTime? _expiresAt;
  int _attempts = 0;

  /// Genera un código, resetea el estado y lo envía al webhook (Sheet).
  Future<void> sendCode(String email) async {
    final code = (100000 + Random.secure().nextInt(900000)).toString();
    _code = code;
    _expiresAt = DateTime.now().add(ttl);
    _attempts = 0;

    final url = EnvConfig.otpWebhookUrl.trim();
    if (url.isEmpty) {
      dev.log('[OtpService] DEV (sin webhook) código para $email = $code');
      return;
    }
    await _dio.post(
      url,
      data: {'email': email, 'otp': code},
      options: Options(
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    dev.log('[OtpService] OTP enviado al webhook para $email');
  }

  /// Verifica el código ingresado contra el último generado.
  OtpResult verify(String input) {
    if (_code == null || _expiresAt == null) return OtpResult.noCode;
    if (DateTime.now().isAfter(_expiresAt!)) return OtpResult.expired;
    if (_attempts >= maxAttempts) return OtpResult.tooMany;

    _attempts++;
    if (input.trim() == _code) {
      _clear();
      return OtpResult.ok;
    }
    return _attempts >= maxAttempts ? OtpResult.tooMany : OtpResult.invalid;
  }

  int get attemptsLeft => (maxAttempts - _attempts).clamp(0, maxAttempts);

  void _clear() {
    _code = null;
    _expiresAt = null;
    _attempts = 0;
  }
}
