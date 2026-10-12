import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// El técnico solicita ingresar con su correo corporativo.
///
/// (El flujo de código de verificación por correo se agregará como un evento
///  adicional cuando el backend/servicio de OTP esté disponible.)
class LoginRequested extends AuthEvent {
  final String email;

  const LoginRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Cierra la sesión del técnico (limpia identidad y storage seguro).
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
