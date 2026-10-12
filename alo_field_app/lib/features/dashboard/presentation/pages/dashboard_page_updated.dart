import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/main_navigation.dart';
import '../../../maps/presentation/bloc/maps_bloc.dart';
import '../../../maps/presentation/bloc/maps_event.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/pages/om_detail_page.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

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
              backgroundColor: const Color(0xFF00A650),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is OrderUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFE3000F),
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
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _SearchBar(controller: _searchController),
            _StatusFilterBar(),
            Expanded(
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardInitial ||
                      state is DashboardLoading) {
                    return const _LoadingView();
                  }

                  if (state is DashboardError) {
                    return _ErrorView(
                      message: state.message,
                      canRetry: state.canRetry,
                      onRetry: _loadOrders,
                    );
                  }

                  if (state is DashboardEmpty) {
                    return _EmptyView(reason: state.reason);
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
      backgroundColor: const Color(0xFF1A1C24),
      title: const Text(
        'Dashboard Técnico',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
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

// ── Barra de búsqueda ──────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1C24),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar OM, cliente, equipo...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.white60),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white60),
                  onPressed: controller.clear,
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha:0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

// ── Filtros por estado ─────────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (prev, curr) =>
          curr is DashboardLoaded ||
          curr is DashboardEmpty ||
          curr is DashboardLoading,
      builder: (context, state) {
        final currentFilter =
            state is DashboardLoaded ? state.statusFilter : null;

        return Container(
          height: 48,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // Filtros por el ciclo REAL de la actividad (estado local), no por
              // el catálogo U_Estado de SAP (que no coincide con el de la OM).
              for (final f in const [
                ('Todas', null),
                ('Sin iniciar', 'NEW'),
                ('En curso', 'INPROGRESS'),
                ('Finalizadas', 'DONE'),
              ])
                _FilterChipItem(
                  label: f.$1,
                  sapCode: f.$2,
                  currentFilter: currentFilter,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final String? sapCode;
  final String? currentFilter;

  const _FilterChipItem({
    required this.label,
    required this.sapCode,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentFilter == sapCode;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => context
            .read<DashboardBloc>()
            .add(FilterOrdersByStatus(sapCode)),
        selectedColor: const Color(0xFFFFCE00),
        checkmarkColor: const Color(0xFF1A1C24),
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected
              ? const Color(0xFF1A1C24)
              : Colors.grey.shade700,
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ── Lista de órdenes ───────────────────────────────────────────────────────────

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
      return const _EmptyView(reason: 'No hay órdenes para los filtros actuales.');
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFFFFCE00),
      backgroundColor: const Color(0xFF1A1C24),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final isUpdating = order.docEntry == updatingDocEntry;
          return _OrderCard(
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

// ── Card de orden ──────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  final bool isUpdating;
  final String? updatingAction;

  /// Estado local del ciclo de esta OM (null = no iniciada).
  final String? localEstado;

  const _OrderCard({
    required this.order,
    this.isUpdating = false,
    this.updatingAction,
    this.localEstado,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = _statusColor(order.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: widget.isUpdating
          ? _UpdatingOverlay(action: widget.updatingAction ?? 'Actualizando...')
          : Column(
              children: [
                // ── Header ─────────────────────────────────────────────
                InkWell(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(16),
                  ),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              order.displayId,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            _PriorityBadge(priority: order.priorityLabel),
                            const SizedBox(width: 8),
                            Icon(
                              _expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          order.clientDisplayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.fullAddress,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              order.technicianName,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const Spacer(),
                            _StatusChip(
                              label: order.displayStatus,
                              color: statusColor,
                            ),
                          ],
                        ),
                        if (order.hasTasks) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.checklist_rtl_outlined,
                                  size: 14, color: Color(0xFF0F6E56)),
                              const SizedBox(width: 4),
                              Text(
                                order.tasksPending > 0
                                    ? '${order.tasksPending} ${order.tasksPending == 1 ? 'tarea pendiente' : 'tareas pendientes'} de ${order.tasksTotal}'
                                    : '${order.tasksTotal} ${order.tasksTotal == 1 ? 'tarea' : 'tareas'} (todas terminadas)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0F6E56),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Contenido expandible ────────────────────────────────
                if (_expanded) ...[
                  const Divider(height: 1),
                  _ExpandedContent(order: order),
                  if (order.docEntry != null && order.docNum != null)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => OmDetailPage(
                                docEntry: order.docEntry!,
                                docNum: order.docNum!,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.assignment_outlined, size: 18),
                          label: const Text('Ver detalle y ejecutar tareas'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F6E56),
                          ),
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  _ActionButtons(order: order, localEstado: widget.localEstado),
                ],
              ],
            ),
    );
  }

  Color _statusColor(String? estado) {
    // Catálogo real de U_Estado de la OM (VID_MTOM): P/L/C/X.
    switch (estado?.toUpperCase().trim()) {
      case 'P':
        return const Color(0xFFFF8C00); // Planificada
      case 'L':
        return const Color(0xFF2196F3); // Liberada
      case 'C':
        return const Color(0xFF00A650); // Cerrada
      case 'X':
        return const Color(0xFFE3000F); // Cancelada
      default:
        return Colors.grey;
    }
  }
}

// ── Contenido expandible ───────────────────────────────────────────────────────

class _ExpandedContent extends StatelessWidget {
  final OrderModel order;

  const _ExpandedContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información adicional del header (campos reales de la OM)
          if (order.asunto != null)
            _InfoRow(
              icon: Icons.subject_outlined,
              label: 'Asunto',
              value: order.asunto!,
            ),
          if (order.equipoDescripcion != null || order.equipoCode != null)
            _InfoRow(
              icon: Icons.precision_manufacturing_outlined,
              label: 'Equipo',
              value: order.equipoDescripcion ?? order.equipoCode!,
            ),
          if (order.tipoOM != null)
            _InfoRow(
              icon: Icons.build_outlined,
              label: 'Tipo mantenimiento',
              value: order.tipoOM!,
            ),
          if (order.fechaProgramada != null)
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Fecha programada',
              value: _formatDate(order.fechaProgramada),
            ),
          if (order.supervisorName != null)
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Supervisor',
              value: order.supervisorName!,
            ),

          // Tareas asignadas (VID_MTOMTACollection)
          if (order.hasTasks) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.checklist_rtl_outlined,
                    size: 16, color: Color(0xFF1A1C24)),
                const SizedBox(width: 6),
                Text(
                  'Tareas: ${order.tasksPending} ${order.tasksPending == 1 ? 'pendiente' : 'pendientes'} de ${order.tasksTotal}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...order.tasks.map((t) => _TaskRow(task: t)),
          ],

          // Materiales / repuestos
          if (order.visibleMaterials.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.build_circle_outlined,
                    size: 16, color: Color(0xFF1A1C24)),
                const SizedBox(width: 6),
                Text(
                  'Repuestos (${order.materialCount})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...order.visibleMaterials.map((line) => _MaterialRow(line: line)),
          ],

          // Comentarios del técnico
          if (order.descripcionProblema.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Descripción del problema:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              order.descripcionProblema,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final OrderTask task;

  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final pending = task.isPending;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            pending ? Icons.radio_button_unchecked : Icons.check_circle,
            size: 16,
            color: pending ? const Color(0xFFFF8C00) : const Color(0xFF00A650),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.displayName,
              style: TextStyle(
                fontSize: 13,
                color: pending ? Colors.black87 : Colors.grey,
                decoration:
                    pending ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          Text(
            task.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  pending ? const Color(0xFFFF8C00) : const Color(0xFF00A650),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final OrderDetailLine line;

  const _MaterialRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              line.itemDescription ?? line.itemCode ?? 'Item desconocido',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            'x${line.quantity?.toStringAsFixed(0) ?? '1'}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botones de acción ──────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final OrderModel order;

  /// Estado local del ciclo (null = no iniciada; 'EC'/'EA'/'EP'/'F').
  final String? localEstado;

  const _ActionButtons({required this.order, this.localEstado});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    final local = localEstado?.toUpperCase().trim();
    final hasDocs = order.docEntry != null && order.docNum != null;

    // Botón del ciclo según el estado LOCAL de la actividad (no el U_Estado SAP):
    //  · sin estado  → Iniciar
    //  · EC          → Llegué
    //  · EA / EP     → Finalizar
    //  · F           → chip "Finalizada"
    Widget? cycleButton;
    if (!hasDocs) {
      cycleButton = null;
    } else if (local == null) {
      cycleButton = _ActionBtn(
        label: 'Iniciar',
        icon: Icons.play_arrow_rounded,
        color: const Color(0xFFFFCE00),
        textColor: const Color(0xFF1A1C24),
        onTap: () => bloc.add(
            InitiateOrder(docEntry: order.docEntry!, docNum: order.docNum!)),
      );
    } else if (local == 'EC') {
      cycleButton = _ActionBtn(
        label: 'Llegué',
        icon: Icons.location_on,
        color: const Color(0xFF2196F3),
        textColor: Colors.white,
        onTap: () => bloc.add(MarkOrderAsArrived(
            docEntry: order.docEntry!, docNum: order.docNum!)),
      );
    } else if (local == 'EA' || local == 'EP') {
      cycleButton = _ActionBtn(
        label: 'Finalizar',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF00A650),
        textColor: Colors.white,
        onTap: () => _showFinishDialog(context, bloc, order),
      );
    } else if (local == 'F') {
      cycleButton = const _DoneChip();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // "Ver ubicación": resuelve la obra (equipo→contrato→dirección) y
          // muestra el mapa. Disponible siempre que la OM tenga equipo.
          if (order.equipoCode != null)
            Expanded(
              child: _ActionBtn(
                label: 'Ver ubicación',
                icon: Icons.place,
                color: const Color(0xFF1A1C24),
                textColor: Colors.white,
                onTap: () => _navigateToObra(context, order),
              ),
            ),
          if (order.equipoCode != null && cycleButton != null)
            const SizedBox(width: 8),
          if (cycleButton != null) Expanded(child: cycleButton),
        ],
      ),
    );
  }

  void _navigateToObra(BuildContext context, OrderModel order) {
    final equipo = order.equipoCode;
    if (equipo == null) return;
    // Carga la obra en el MapsBloc global y salta a la pestaña Mapa,
    // donde se muestra el mapa embebido + "Cómo llegar".
    context.read<MapsBloc>().add(
          LoadObraForEquipo(
            equipo,
            equipoName: order.equipoDescripcion,
            docNumRtov: order.docNumRtov,
            tallerCode: order.taller,
          ),
        );
    mainTabIndex.value = kMapsTabIndex;
  }

  void _showFinishDialog(
    BuildContext context,
    DashboardBloc bloc,
    OrderModel order,
  ) {
    final commentsCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Finalizar ${order.displayId}'),
        content: TextField(
          controller: commentsCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Solución aplicada / observaciones...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A650),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(FinishOrder(
                docEntry: order.docEntry!,
                docNum: order.docNum!,
                comments: commentsCtrl.text.trim(),
              ));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _DoneChip extends StatelessWidget {
  const _DoneChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF00A650).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00A650).withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 18, color: Color(0xFF00A650)),
          SizedBox(width: 6),
          Text('Finalizada',
              style: TextStyle(
                  color: Color(0xFF00A650), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

// ── Badges y chips pequeños ────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final isHigh = priority == 'Alta';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isHigh
            ? const Color(0xFFE3000F).withValues(alpha:0.1)
            : Colors.orange.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isHigh ? const Color(0xFFE3000F) : Colors.orange,
        ),
      ),
    );
  }
}

// ── Vistas de estado vacío / error / cargando ──────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFFFCE00)),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando órdenes desde SAP...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String reason;

  const _EmptyView({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin órdenes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final bool canRetry;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.canRetry,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 72,
              color: Color(0xFFE3000F),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (canRetry) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCE00),
                  foregroundColor: const Color(0xFF1A1C24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Overlay de actualización ───────────────────────────────────────────────────

class _UpdatingOverlay extends StatelessWidget {
  final String action;

  const _UpdatingOverlay({required this.action});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFFFFCE00)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              action,
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
