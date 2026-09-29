import 'package:equatable/equatable.dart';

abstract class SignatureEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSignatureRequested extends SignatureEvent {}
