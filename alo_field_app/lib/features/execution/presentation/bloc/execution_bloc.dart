import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dashboard/data/services/sap_auth_service.dart';
import '../../data/models/service_call_item.dart';
import '../../data/models/started_activity.dart';
import '../../data/services/activity_store.dart';
import '../../data/services/execution_service.dart';
import 'execution_event.dart';
import 'execution_state.dart';

class ExecutionBloc extends Bloc<ExecutionEvent, ExecutionState> {
  ExecutionBloc({
    required ExecutionService service,
    required ActivityStore activityStore,
  })  : _service = service,
        _activityStore = activityStore,
        super(const ExecutionInitial()) {
    on<LoadMyExecutions>(_onLoad);
  }

  final ExecutionService _service;
  final ActivityStore _activityStore;

  Future<void> _onLoad(
    LoadMyExecutions event,
    Emitter<ExecutionState> emit,
  ) async {
    if (event.empId.isEmpty && (event.userId == null || event.userId!.isEmpty)) {
      emit(ExecutionError(
        'No se pudo identificar al técnico en la sesión.',
        onlyOpen: event.onlyOpen,
      ));
      return;
    }

    emit(ExecutionLoading(onlyOpen: event.onlyOpen));

    // 1) Actividades (OM) iniciadas localmente: fuente confiable, siempre se
    //    muestran aunque SAP/OSCL falle.
    List<StartedActivity> activities = const [];
    try {
      activities = await _activityStore.forTechnician(
        event.empId,
        open: event.onlyOpen,
      );
    } catch (e) {
      dev.log('[ExecutionBloc] Error leyendo actividades locales: $e');
    }

    // 2) Llamadas de servicio (OSCL) desde SAP.
    try {
      final items = await _service.fetchMyServiceCalls(
        empId: event.empId,
        userId: event.userId,
        onlyOpen: event.onlyOpen,
      );
      emit(ExecutionLoaded(
        activities: activities,
        items: items,
        onlyOpen: event.onlyOpen,
      ));
    } on SapAuthException catch (e) {
      _emitSoftError(emit, activities, event.onlyOpen, 'Sesión SAP: ${e.message}');
    } on SapNetworkException catch (e) {
      _emitSoftError(emit, activities, event.onlyOpen, 'Sin conexión: ${e.message}');
    } on SapServiceException catch (e) {
      _emitSoftError(emit, activities, event.onlyOpen, 'Error SAP: ${e.message}');
    } catch (e) {
      dev.log('[ExecutionBloc] Error: $e');
      _emitSoftError(emit, activities, event.onlyOpen, 'Error inesperado.');
    }
  }

  /// Si OSCL falla pero hay actividades locales, igual las mostramos (sin OSCL);
  /// solo si no hay nada local propagamos el error.
  void _emitSoftError(
    Emitter<ExecutionState> emit,
    List<StartedActivity> activities,
    bool onlyOpen,
    String message,
  ) {
    if (activities.isNotEmpty) {
      emit(ExecutionLoaded(
        activities: activities,
        items: const <ServiceCallItem>[],
        onlyOpen: onlyOpen,
      ));
    } else {
      emit(ExecutionError(message, onlyOpen: onlyOpen));
    }
  }
}
