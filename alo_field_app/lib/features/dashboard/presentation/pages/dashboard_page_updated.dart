import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../orders/data/models/order_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/dashboard_filters.dart';
import '../widgets/dashboard_state_views.dart';
import '../widgets/order_card.dart';

/// Dashboard principal de órdenes de taller con integración SAP B1.
///
/// Maneja 7 estados del BLoC: Initial, Loading, Loaded, Empty, Error,
/// Updating y UpdateSuccess/Error. Incluye búsqueda en tiempo real,
/// filtros por estado y pull-to-refresh.
class DashboardPageUpdated extends StatefulWidget {
  /// Código del técnico autenticado (OHEM.EmployeeID) — filtra las OM por
  /// `VID_MTOM.U_UsrRes`.
  final String? tecnicoCode;

  const DashboardPageUpdated({super.key, this.tecnicoCode});

  @override
  State<DashboardPageUpdated> createState() => _DashboardPageUpdatedState();
}

class _DashboardPageUpdatedState extends State<DashboardPageUpdated> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    // Carga las OM (VID_MTOM) abiertas asignadas al técnico (U_UsrRes).
    context.read<DashboardBloc>().add(
          LoadDashboardOrders(tecnicoCode: widget.tecnicoCode),
        );
  }

  void _onSearchChanged() {
    context
        .read<DashboardBloc>()
        .add(SearchOrders(_searchController.text));
  }

  Future<void> _onRefresh() async {
    context.read<DashboardBloc>().add(
          RefreshDashboardOrders(tecnicoCode: widget.tecnicoCode),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listenWhen: (prev, curr) =>
          curr is OrderUpdateSuccess || curr is OrderUpdateError,
      listener: (context, state) {
        if (state is OrderUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is OrderUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: _loadOrders,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            DashboardSearchBar(controller: _searchController),
            const DashboardStatusFilterBar(),
            Expanded(
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardInitial ||
                      state is DashboardLoading) {
                    return const DashboardLoadingView();
                  }

                  if (state is DashboardError) {
                    return DashboardErrorView(
                      message: state.message,
                      canRetry: state.canRetry,
                      onRetry: _loadOrders,
                    );
                  }

                  if (state is DashboardEmpty) {
                    return DashboardEmptyView(reason: state.reason);
                  }

                  if (state is DashboardLoaded) {
                    return _OrdersList(
                      orders: state.displayedOrders,
                      onRefresh: _onRefresh,
                      scrollController: _scrollController,
                      localEstados: state.localEstados,
                    );
                  }

                  // Estados de actualización (Updating/Success/Error):
                  // se mantiene la lista visible si hay caché.
                  if (state is OrderUpdating) {
                    return _OrdersList(
                      orders: state.previousOrders,
                      onRefresh: _onRefresh,
                      scrollController: _scrollController,
                      updatingDocEntry: state.docEntry,
                      updatingAction: state.action,
                      localEstados: state.localEstados,
                    );
                  }

                  if (state is OrderUpdateError) {
                    return _OrdersList(
                      orders: state.previousOrders,
                      onRefresh: _onRefresh,
                      scrollController: _scrollController,
                      localEstados: state.localEstados,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.aloDarkBlue,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text('Dashboard Técnico'),
      actions: [
        BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final showAll = state is DashboardLoaded ? state.showAll : false;
            return IconButton(
              icon: Icon(
                showAll ? Icons.filter_list_off : Icons.filter_list,
                color: Colors.white,
              ),
              tooltip: showAll ? 'Solo activas' : 'Mostrar todas',
              onPressed: () => context
                  .read<DashboardBloc>()
                  .add(const ToggleShowAllOrders()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Actualizar',
          onPressed: _onRefresh,
        ),
      ],
    );
  }
}

// ── Lista de órdenes ────────────────────────────────────────────────────

class _OrdersList extends StatelessWidget {
  final List<OrderModel> orders;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final int? updatingDocEntry;
  final String? updatingAction;
  final Map<int, String> localEstados;

  const _OrdersList({
    required this.orders,
    required this.onRefresh,
    required this.scrollController,
    this.updatingDocEntry,
    this.updatingAction,
    this.localEstados = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const DashboardEmptyView(
        reason: 'No hay órdenes para los filtros actuales.',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.aloYellow,
      backgroundColor: AppColors.aloDarkBlue,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final isUpdating = order.docEntry == updatingDocEntry;
          return OrderCard(
            order: order,
            isUpdating: isUpdating,
            updatingAction: isUpdating ? updatingAction : null,
            localEstado: localEstados[order.docEntry],
          );
        },
      ),
    );
  }
}