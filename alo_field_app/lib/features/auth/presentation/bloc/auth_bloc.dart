import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/services/otp_service.dart';
import '../../../../core/session/session_manager.dart';
import '../../../dashboard/data/services/sap_auth_service.dart';
import '../../data/models/technician.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required SessionManager sessionManager,
    required SapAuthService sapAuth,
    required OtpService otpService,
  })  : _repository = repository,
        _session = sessionManager,
        _sapAuth = sapAuth,
        _otp = otpService,
        super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<VerifyOtpRequested>(_onVerifyOtp);
    on<ResendOtpRequested>(_onResendOtp);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repository;
  final SessionManager _session;
  final SapAuthService _sapAuth;
  final OtpService _otp;

  static final _emailRegex = RegExp(r'^[\w.\-+]+@([\w-]+\.)+[\w-]{2,}$');

  // Identidad pendiente entre "pedir código" y "verificar código".
  Technician? _pendingTech;
  String? _pendingEmail;

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final email = event.email.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      emit(const AuthError('Ingresa un correo válido.', canRetry: false));
      return;
    }

    emit(const AuthLoading());
    try {
      var technician = await _repository.login(email);
      // Correo de prueba (dev): entra al OTP aunque no sea técnico en OHEM.
      if (technician == null &&
          EnvConfig.otpDevEmails.contains(email.toLowerCase())) {
        technician = Technician(
            code: '0', email: email, firstName: 'Prueba', lastName: 'OTP');
      }
      if (technician == null) {
        emit(AuthNotRegistered(email));
        return;
      }
      _pendingTech = technician;
      _pendingEmail = email;
      await _otp.sendCode(email);
      emit(AuthOtpSent(email));
    } on AuthFailure catch (e) {
      emit(AuthError(e.message, canRetry: e.isRetryable));
    } catch (e) {
      dev.log('[AuthBloc] Error al enviar OTP: $e');
      emit(const AuthError('No se pudo enviar el código. Intenta de nuevo.'));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final tech = _pendingTech;
    if (tech == null) {
      emit(const AuthOtpError('Vuelve a ingresar tu correo.', mustResend: true));
      return;
    }
    emit(const AuthOtpVerifying());
    switch (_otp.verify(event.code)) {
      case OtpResult.ok:
        await _session.save(tech);
        _pendingTech = null;
        _pendingEmail = null;
        dev.log('[AuthBloc] Técnico autenticado: ${tech.code}');
        emit(AuthAuthenticated(tech));
      case OtpResult.invalid:
        emit(AuthOtpError(
            'Código incorrecto. Te quedan ${_otp.attemptsLeft} intento(s).'));
      case OtpResult.expired:
        emit(const AuthOtpError('El código expiró. Reenvía uno nuevo.',
            mustResend: true));
      case OtpResult.tooMany:
        emit(const AuthOtpError('Demasiados intentos. Reenvía un código nuevo.',
            mustResend: true));
      case OtpResult.noCode:
        emit(const AuthOtpError('Reenvía un código para continuar.',
            mustResend: true));
    }
  }

  Future<void> _onResendOtp(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final email = _pendingEmail;
    if (email == null) {
      emit(const AuthError('Vuelve a ingresar tu correo.', canRetry: false));
      return;
    }
    emit(const AuthLoading());
    try {
      await _otp.sendCode(email);
      emit(AuthOtpSent(email, resent: true));
    } catch (e) {
      dev.log('[AuthBloc] Error al reenviar OTP: $e');
      emit(const AuthOtpError('No se pudo reenviar el código.',
          mustResend: true));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _sapAuth.logout();
    } catch (_) {
      // El logout SAP puede fallar silenciosamente; la sesión expira igual.
    }
    await _session.clear();
    emit(const AuthUnauthenticated());
  }
}
