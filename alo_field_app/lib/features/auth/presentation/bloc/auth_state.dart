import 'package:equatable/equatable.dart';

import '../../data/models/technician.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Técnico autenticado con su identidad resuelta desde OHEM.
class AuthAuthenticated extends AuthState {
  final Technician technician;

  const AuthAuthenticated(this.technician);

  @override
  List<Object?> get props => [technician.code];
}

/// El correo ingresado no existe en la tabla maestra de técnicos.
class AuthNotRegistered extends AuthState {
  final String email;

  const AuthNotRegistered(this.email);

  @override
  List<Object?> get props => [email];
}

/// Sin sesión (estado tras logout o al iniciar sin sesión previa).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final bool canRetry;

  const AuthError(this.message, {this.canRetry = true});

  @override
  List<Object?> get props => [message, canRetry];
}
