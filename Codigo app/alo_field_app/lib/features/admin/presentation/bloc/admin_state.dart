import 'package:equatable/equatable.dart';

abstract class AdminState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final Map<String, dynamic> stats;

  AdminLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class AdminError extends AdminState {
  final String message;

  AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
