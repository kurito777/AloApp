import 'package:equatable/equatable.dart';

abstract class SignatureState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignatureInitial extends SignatureState {}

class SignatureSaving extends SignatureState {}

class SignatureSaved extends SignatureState {}

class SignatureError extends SignatureState {
  final String message;

  SignatureError(this.message);

  @override
  List<Object?> get props => [message];
}
