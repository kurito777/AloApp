import 'package:equatable/equatable.dart';

import '../../data/models/service_call_item.dart';
import '../../data/models/started_activity.dart';

abstract class ExecutionState extends Equatable {
  const ExecutionState();

  @override
  List<Object?> get props => [];
}

class ExecutionInitial extends ExecutionState {
  const ExecutionInitial();
}

class ExecutionLoading extends ExecutionState {
  final bool onlyOpen;
  const ExecutionLoading({required this.onlyOpen});

  @override
  List<Object?> get props => [onlyOpen];
}

class ExecutionLoaded extends ExecutionState {
  /// Actividades (OM) iniciadas por el técnico (fuente local).
  final List<StartedActivity> activities;

  /// Llamadas de servicio (OSCL) asignadas al técnico.
  final List<ServiceCallItem> items;
  final bool onlyOpen;

  const ExecutionLoaded({
    required this.activities,
    required this.items,
    required this.onlyOpen,
  });

  bool get isEmpty => activities.isEmpty && items.isEmpty;

  @override
  List<Object?> get props => [activities, items, onlyOpen];
}

class ExecutionError extends ExecutionState {
  final String message;
  final bool onlyOpen;

  const ExecutionError(this.message, {required this.onlyOpen});

  @override
  List<Object?> get props => [message, onlyOpen];
}
