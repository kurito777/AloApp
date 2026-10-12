import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/session_manager.dart';
import '../../../dashboard/data/services/sap_auth_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required SessionManager sessionManager,
    required SapAuthService sapAuth,
  })  : _repository = repository,
        _session = sessionManager,
        _sapAuth = sapAuth,
        super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repository;
  final SessionManager _session;
  final SapAuthService _sapAuth;

  static final _emailRegex = RegExp(r'^[\w.\-+]+@([\w-]+\.)+[\w-]{2,}$');

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
      final technician = await _repository.login(email);

      if (technician == null) {
        emit(AuthNotRegistered(email));
        return;
      }

      await _session.save(technician);
      dev.log('[AuthBloc] Técnico autenticado: ${technician.code}');
      emit(AuthAuthenticated(technician));
    } on AuthFailure catch (e) {
      emit(AuthError(e.message, canRetry: e.isRetryable));
    } catch (e) {
      dev.log('[AuthBloc] Error inesperado en login: $e');
      emit(const AuthError('Error inesperado al iniciar sesión.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Cierra la sesión SAP y limpia la identidad local.
    try {
      await _sapAuth.logout();
    } catch (_) {
      // El logout SAP puede fallar silenciosamente; la sesión expira igual.
    }
    await _session.clear();
    emit(const AuthUnauthenticated());
  }
}
