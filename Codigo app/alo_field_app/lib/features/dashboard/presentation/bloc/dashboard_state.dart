import 'package:equatable/equatable.dart';

import '../../../orders/data/models/order_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cualquier carga.
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Cargando órdenes desde SAP (spinner global).
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// Órdenes cargadas y listas para mostrar.
class DashboardLoaded extends DashboardState {
  /// Todas las órdenes recibidas de SAP (cache en memoria).
  final List<OrderModel> orders;

  /// Órdenes visibles tras aplicar filtro de estado y búsqueda.
  final List<OrderModel> displayedOrders;

  /// Filtro de estado activo (P, EC, EA, EP, F, C) o null = todos.
  final String? statusFilter;

  /// Texto de búsqueda activo.
  final String searchQuery;

  /// true = muestra también finalizadas/canceladas; false = solo activas.
  final bool showAll;

  /// Estado LOCAL del ciclo de la actividad por OM (docEntry → 'EC'/'EA'/'EP'/'F').
  /// Ausente = la OM aún no ha sido iniciada por el técnico. Proviene del
  /// ActivityStore, NO del U_Estado de SAP.
  final Map<int, String> localEstados;

  const DashboardLoaded({
    required this.orders,
    required this.displayedOrders,
    this.statusFilter,
    this.searchQuery = '',
    this.showAll = false,
    this.localEstados = const {},
  });

  DashboardLoaded copyWith({
    List<OrderModel>? orders,
    List<OrderModel>? displayedOrders,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    bool? showAll,
    Map<int, String>? localEstados,
  }) {
    return DashboardLoaded(
      orders: orders ?? this.orders,
      displayedOrders: displayedOrders ?? this.displayedOrders,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      showAll: showAll ?? this.showAll,
      localEstados: localEstados ?? this.localEstados,
    );
  }

  @override
  List<Object?> get props =>
      [orders, displayedOrders, statusFilter, searchQuery, showAll, localEstados];
}

/// No hay órdenes para los filtros actuales.
class DashboardEmpty extends DashboardState {
  final String reason;

  const DashboardEmpty({
    this.reason = 'No se encontraron órdenes.',
  });

  @override
  List<Object?> get props => [reason];
}

/// Error al cargar órdenes.
class DashboardError extends DashboardState {
  final String message;
  final bool canRetry;

  const DashboardError({required this.message, this.canRetry = true});

  @override
  List<Object?> get props => [message, canRetry];
}

/// Actualizando el estado de una OT en SAP (spinner local en la card).
class OrderUpdating extends DashboardState {
  final int docEntry;
  final int docNum;
  final String action;

  /// Órdenes previas para mantener la lista visible durante la actualización.
  final List<OrderModel> previousOrders;

  /// Estado local del ciclo por OM (ver [DashboardLoaded.localEstados]).
  final Map<int, String> localEstados;

  const OrderUpdating({
    required this.docEntry,
    required this.docNum,
    required this.action,
    required this.previousOrders,
    this.localEstados = const {},
  });

  @override
  List<Object?> get props => [docEntry, docNum, action, localEstados];
}

/// Actualización de OT completada exitosamente.
class OrderUpdateSuccess extends DashboardState {
  final OrderModel updatedOrder;
  final String message;

  const OrderUpdateSuccess({
    required this.updatedOrder,
    required this.message,
  });

  @override
  List<Object?> get props => [updatedOrder, message];
}

/// Error al actualizar el estado de una OT.
class OrderUpdateError extends DashboardState {
  final int docEntry;
  final int docNum;
  final String message;

  /// Órdenes previas para restaurar la UI al estado anterior.
  final List<OrderModel> previousOrders;

  /// Estado local del ciclo por OM (ver [DashboardLoaded.localEstados]).
  final Map<int, String> localEstados;

  const OrderUpdateError({
    required this.docEntry,
    required this.docNum,
    required this.message,
    required this.previousOrders,
    this.localEstados = const {},
  });

  @override
  List<Object?> get props => [docEntry, docNum, message, localEstados];
}
