import 'package:equatable/equatable.dart';

abstract class ExecutionEvent extends Equatable {
  const ExecutionEvent();

  @override
  List<Object?> get props => [];
}

/// Carga los servicios del técnico. [onlyOpen] true = Pendientes; false = Historial.
class LoadMyExecutions extends ExecutionEvent {
  final String empId;
  final String? userId;
  final bool onlyOpen;

  const LoadMyExecutions({
    required this.empId,
    this.userId,
    required this.onlyOpen,
  });

  @override
  List<Object?> get props => [empId, userId, onlyOpen];
}
