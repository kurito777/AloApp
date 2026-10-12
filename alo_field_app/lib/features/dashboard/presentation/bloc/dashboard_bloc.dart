import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/session_manager.dart';
import '../../../execution/data/models/started_activity.dart';
import '../../../execution/data/services/activity_store.dart';
import '../../../orders/data/models/order_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// BLoC principal del dashboard de órdenes de taller.
///
/// Gestiona la carga, filtrado, búsqueda y actualización de OTs desde SAP B1.
/// Mantiene un caché en memoria para filtrado instantáneo sin re-llamadas a SAP.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required DashboardRepository repository,
    required ActivityStore activityStore,
    required SessionManager sessionManager,
  })  : _repository = repository,
        _activityStore = activityStore,
        _session = sessionManager,
        super(const DashboardInitial()) {
    on<LoadDashboardOrders>(_onLoadDashboardOrders);
    on<RefreshDashboardOrders>(_onRefreshDashboardOrders);
    on<FilterOrdersByStatus>(_onFilterOrdersByStatus);
    on<SearchOrders>(_onSearchOrders);
    on<InitiateOrder>(_onInitiateOrder);
    on<MarkOrderAsArrived>(_onMarkOrderAsArrived);
    on<FinishOrder>(_onFinishOrder);
    on<ToggleShowAllOrders>(_onToggleShowAllOrders);
  }

  final DashboardRepository _repository;
  final ActivityStore _activityStore;
  final SessionManager _session;

  /// Caché en memoria de todas las órdenes cargadas desde SAP.
  List<OrderModel> _cachedOrders = [];

  /// Estado LOCAL del ciclo por OM (docEntry → 'EC'/'EA'/'EP'/'F'), tomado del
  /// ActivityStore. Ausente = la OM no ha sido iniciada.
  Map<int, String> _localEstados = {};

  Future<void> _refreshLocalEstados() async {
    final tech = _techCode;
    if (tech.isEmpty) {
      _localEstados = {};
      return;
    }
    try {
      final list = await _activityStore.forTechnician(tech);
      _localEstados = {for (final a in list) a.docEntry: a.estado};
    } catch (_) {
      _localEstados = {};
    }
  }

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> _onLoadDashboardOrders(
    LoadDashboardOrders event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _loadOrders(emit, tecnicoCode: event.tecnicoCode);
  }

  Future<void> _onRefreshDashboardOrders(
    RefreshDashboardOrders event,
    Emitter<DashboardState> emit,
  ) async {
    // Durante refresh mantenemos las órdenes actuales si las hay.
    final currentOrders = _cachedOrders;
    if (currentOrders.isEmpty) emit(const DashboardLoading());

    await _loadOrders(emit, tecnicoCode: event.tecnicoCode);
  }

  Future<void> _loadOrders(
    Emitter<DashboardState> emit, {
    String? tecnicoCode,
  }) async {
    // Fallback a la identidad de la sesión si el evento no trae el código.
    final code = (tecnicoCode == null || tecnicoCode.isEmpty)
        ? _techCode
        : tecnicoCode;
    if (code.isEmpty) {
      emit(const DashboardEmpty(
        reason: 'No se pudo identificar tu código de técnico (OHEM.EmployeeID) '
            'en la sesión. Contacta al administrador.',
      ));
      return;
    }
    try {
      final orders = await _repository.fetchDashboardOrders(tecnicoCode: code);

      _cachedOrders = orders;

      if (orders.isEmpty) {
        emit(const DashboardEmpty(reason: 'No hay órdenes asignadas.'));
        return;
      }

      await _refreshLocalEstados();
      final displayed = _applyFilters(orders);
      emit(DashboardLoaded(
        orders: orders,
        displayedOrders: displayed,
        localEstados: _localEstados,
      ));
    } on RepositoryException catch (e) {
      dev.log('[DashboardBloc] Error cargando órdenes: ${e.message}');
      emit(DashboardError(message: e.message, canRetry: e.isRetryable));
    } catch (e) {
      dev.log('[DashboardBloc] Error inesperado: $e');
      emit(DashboardError(
        message: 'Error inesperado al cargar órdenes.',
        canRetry: true,
      ));
    }
  }

  // ── Filtrado por estado ────────────────────────────────────────────────────

  void _onFilterOrdersByStatus(
    FilterOrdersByStatus event,
    Emitter<DashboardState> emit,
  ) {
    if (state is! DashboardLoaded) return;
    final current = state as DashboardLoaded;

    final displayed = _applyFilters(
      _cachedOrders,
      statusFilter: event.status,
      searchQuery: current.searchQuery,
      showAll: current.showAll,
    );

    if (displayed.isEmpty) {
      emit(current.copyWith(
        displayedOrders: displayed,
        statusFilter: event.status,
        clearStatusFilter: event.status == null,
      ));
      return;
    }

    emit(current.copyWith(
      displayedOrders: displayed,
      statusFilter: event.status,
      clearStatusFilter: event.status == null,
    ));
  }

  // ── Búsqueda en tiempo real ────────────────────────────────────────────────

  void _onSearchOrders(
    SearchOrders event,
    Emitter<DashboardState> emit,
  ) {
    if (state is! DashboardLoaded) return;
    final current = state as DashboardLoaded;

    final displayed = _applyFilters(
      _cachedOrders,
      statusFilter: current.statusFilter,
      searchQuery: event.query,
      showAll: current.showAll,
    );

    emit(current.copyWith(
      displayedOrders: displayed,
      searchQuery: event.query,
    ));
  }

  // ── Toggle mostrar todas ───────────────────────────────────────────────────

  void _onToggleShowAllOrders(
    ToggleShowAllOrders event,
    Emitter<DashboardState> emit,
  ) {
    if (state is! DashboardLoaded) return;
    final current = state as DashboardLoaded;

    final newShowAll = !current.showAll;
    final displayed = _applyFilters(
      _cachedOrders,
      statusFilter: current.statusFilter,
      searchQuery: current.searchQuery,
      showAll: newShowAll,
    );

    emit(current.copyWith(displayedOrders: displayed, showAll: newShowAll));
  }

  // ── Iniciar OT ─────────────────────────────────────────────────────────────

  Future<void> _onInitiateOrder(
    InitiateOrder event,
    Emitter<DashboardState> emit,
  ) async {
    await _updateOrder(
      emit,
      docEntry: event.docEntry,
      docNum: event.docNum,
      action: 'Iniciando actividad',
      successMessage: 'OM-${event.docNum} iniciada — aparece en Mis Servicios',
      newEstado: 'EC',
      perform: () => _repository.initiateOrder(event.docEntry),
      afterSuccess: () => _startActivity(event.docEntry, 'EC'),
    );
  }

  // ── Marcar llegada ─────────────────────────────────────────────────────────

  Future<void> _onMarkOrderAsArrived(
    MarkOrderAsArrived event,
    Emitter<DashboardState> emit,
  ) async {
    await _updateOrder(
      emit,
      docEntry: event.docEntry,
      docNum: event.docNum,
      action: 'Registrando llegada',
      successMessage: 'OM-${event.docNum} — Llegada registrada',
      newEstado: 'EA',
      perform: () => _repository.markArrived(
        event.docEntry,
        lat: event.gpsLat,
        lng: event.gpsLng,
      ),
      afterSuccess: () =>
          _activityStore.setEstado(event.docEntry, _techCode, 'EA'),
    );
  }

  // ── Finalizar OT ───────────────────────────────────────────────────────────

  Future<void> _onFinishOrder(
    FinishOrder event,
    Emitter<DashboardState> emit,
  ) async {
    await _updateOrder(
      emit,
      docEntry: event.docEntry,
      docNum: event.docNum,
      action: 'Finalizando actividad',
      successMessage: 'OM-${event.docNum} finalizada — movida a Historial',
      newEstado: 'F',
      perform: () => _repository.finishOrder(
        event.docEntry,
        solucion: event.comments,
        comentarios: event.comments,
      ),
      afterSuccess: () => _activityStore.setEstado(
        event.docEntry,
        _techCode,
        'F',
        finishComments: event.comments,
      ),
    );
  }

  // ── Sincronización con el store de actividades ("Mis Servicios") ───────────

  String get _techCode => _session.technicianCode ?? '';

  /// Crea la actividad en el store al iniciarla, tomando los datos de la OM
  /// desde el caché del dashboard.
  Future<void> _startActivity(int docEntry, String estado) async {
    final tech = _techCode;
    if (tech.isEmpty) return;
    OrderModel? order;
    for (final o in _cachedOrders) {
      if (o.docEntry == docEntry) {
        order = o;
        break;
      }
    }
    if (order == null) return;
    final now = DateTime.now();
    await _activityStore.upsert(StartedActivity(
      docEntry: docEntry,
      docNum: order.docNum ?? 0,
      technicianCode: tech,
      estado: estado,
      cliente: order.clientDisplayName,
      equipoCode: order.equipoCode,
      equipoName: order.equipoDescripcion,
      direccion: order.fullAddress,
      taller: order.taller,
      docNumRtov: order.docNumRtov,
      startedAt: now,
      updatedAt: now,
    ));
  }

  // ── Helper: actualizar OT con manejo de estado ─────────────────────────────

  Future<void> _updateOrder(
    Emitter<DashboardState> emit, {
    required int docEntry,
    required int docNum,
    required String action,
    required String successMessage,
    required String newEstado,
    required Future<void> Function() perform,
    Future<void> Function()? afterSuccess,
  }) async {
    final previousOrders = List<OrderModel>.from(_cachedOrders);

    emit(OrderUpdating(
      docEntry: docEntry,
      docNum: docNum,
      action: action,
      previousOrders: previousOrders,
      localEstados: _localEstados,
    ));

    try {
      await perform();

      // Sincroniza el store de actividades ("Mis Servicios") tras el éxito y
      // recalcula el estado local del ciclo (fuente de verdad de los botones).
      if (afterSuccess != null) await afterSuccess();
      await _refreshLocalEstados();

      final updated = _cachedOrders.firstWhere(
        (o) => o.docEntry == docEntry,
        orElse: () => OrderModel(docEntry: docEntry, docNum: docNum),
      );

      emit(OrderUpdateSuccess(updatedOrder: updated, message: successMessage));

      // Restaurar estado Loaded (los datos SAP no cambian; el ciclo es local).
      final displayed = _applyFilters(_cachedOrders);
      emit(DashboardLoaded(
        orders: _cachedOrders,
        displayedOrders: displayed,
        localEstados: _localEstados,
      ));
    } on RepositoryException catch (e) {
      dev.log('[DashboardBloc] Error actualizando OM-$docNum: ${e.message}');
      emit(OrderUpdateError(
        docEntry: docEntry,
        docNum: docNum,
        message: e.message,
        previousOrders: previousOrders,
        localEstados: _localEstados,
      ));

      // Restaurar lista previa tras el error.
      _cachedOrders = previousOrders;
      final displayed = _applyFilters(previousOrders);
      emit(DashboardLoaded(
        orders: previousOrders,
        displayedOrders: displayed,
        localEstados: _localEstados,
      ));
    }
  }

  // ── Filtrado local (sin llamadas a SAP) ────────────────────────────────────

  List<OrderModel> _applyFilters(
    List<OrderModel> orders, {
    String? statusFilter,
    String? searchQuery,
    bool showAll = false,
  }) {
    var result = orders;

    // Por defecto solo activas; showAll incluye finalizadas y canceladas.
    if (!showAll) {
      result = result.where((o) => o.isActive).toList();
    }

    // Filtro por CICLO de la actividad (estado local), no por U_Estado de SAP:
    //  · NEW        → aún no iniciada (sin estado local)
    //  · INPROGRESS → iniciada y no finalizada (EC/EA/EP)
    //  · DONE       → finalizada localmente (F)
    if (statusFilter != null && statusFilter.isNotEmpty) {
      result = result.where((o) {
        final est = _localEstados[o.docEntry]?.toUpperCase();
        switch (statusFilter) {
          case 'NEW':
            return est == null;
          case 'INPROGRESS':
            return est != null && est != 'F';
          case 'DONE':
            return est == 'F';
          default:
            return true;
        }
      }).toList();
    }

    // Búsqueda por texto (OT ID, cliente, dirección, técnico).
    final q = searchQuery?.toLowerCase().trim() ?? '';
    if (q.isNotEmpty) {
      result = result.where((o) {
        return (o.displayId.toLowerCase().contains(q)) ||
            (o.clientDisplayName.toLowerCase().contains(q)) ||
            (o.fullAddress.toLowerCase().contains(q)) ||
            (o.technicianName.toLowerCase().contains(q)) ||
            (o.docNum?.toString().contains(q) ?? false);
      }).toList();
    }

    return result;
  }
}
