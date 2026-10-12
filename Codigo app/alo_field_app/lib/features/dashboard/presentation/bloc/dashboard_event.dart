import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Carga inicial de OM (VID_MTOM) del técnico responsable (U_UsrRes = EmployeeID).
class LoadDashboardOrders extends DashboardEvent {
  final String? tecnicoCode;

  const LoadDashboardOrders({this.tecnicoCode});

  @override
  List<Object?> get props => [tecnicoCode];
}

/// Recarga forzada desde SAP (pull-to-refresh).
class RefreshDashboardOrders extends DashboardEvent {
  final String? tecnicoCode;

  const RefreshDashboardOrders({this.tecnicoCode});

  @override
  List<Object?> get props => [tecnicoCode];
}

/// Filtra las órdenes visibles por estado SAP (P, EC, EA, EP, F, C).
/// Usa null para mostrar todos los estados.
class FilterOrdersByStatus extends DashboardEvent {
  final String? status;

  const FilterOrdersByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

/// Búsqueda en tiempo real por texto (cliente, OT ID, dirección).
class SearchOrders extends DashboardEvent {
  final String query;

  const SearchOrders(this.query);

  @override
  List<Object?> get props => [query];
}

/// Inicia la OT: cambia estado a "En Camino" (EC) en SAP.
class InitiateOrder extends DashboardEvent {
  final int docEntry;
  final int docNum;

  const InitiateOrder({required this.docEntry, required this.docNum});

  @override
  List<Object?> get props => [docEntry, docNum];
}

/// Registra llegada al sitio: estado "En Área" (EA) + GPS opcional.
class MarkOrderAsArrived extends DashboardEvent {
  final int docEntry;
  final int docNum;
  final double? gpsLat;
  final double? gpsLng;

  const MarkOrderAsArrived({
    required this.docEntry,
    required this.docNum,
    this.gpsLat,
    this.gpsLng,
  });

  @override
  List<Object?> get props => [docEntry, docNum, gpsLat, gpsLng];
}

/// Finaliza la OT: estado "Finalizada" (F) con solución y comentarios.
class FinishOrder extends DashboardEvent {
  final int docEntry;
  final int docNum;
  final String? comments;
  final List<String> photoUrls;

  const FinishOrder({
    required this.docEntry,
    required this.docNum,
    this.comments,
    this.photoUrls = const [],
  });

  @override
  List<Object?> get props => [docEntry, docNum, comments, photoUrls];
}

/// Alterna entre mostrar solo órdenes activas o todas.
class ToggleShowAllOrders extends DashboardEvent {
  const ToggleShowAllOrders();
}
