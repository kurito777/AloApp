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

/// Verifica el código OTP ingresado por el técnico.
class VerifyOtpRequested extends AuthEvent {
  final String code;

  const VerifyOtpRequested(this.code);

  @override
  List<Object?> get props => [code];
}

/// Reenvía un nuevo código OTP al correo/Sheet.
class ResendOtpRequested extends AuthEvent {
  const ResendOtpRequested();
}

/// Cierra la sesión del técnico (limpia identidad y storage seguro).
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
