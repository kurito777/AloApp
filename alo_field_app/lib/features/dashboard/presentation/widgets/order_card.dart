import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/pages/om_detail_page.dart';
import 'dashboard_state_views.dart';
import 'order_action_buttons.dart';
import 'order_badges.dart';
import 'order_expanded_content.dart';

/// Tarjeta de una orden de mantención dentro de la lista del dashboard.
class OrderCard extends StatefulWidget {
  final OrderModel order;
  final bool isUpdating;
  final String? updatingAction;

  /// Estado local del ciclo de esta OM (null = no iniciada).
  final String? localEstado;

  const OrderCard({
    super.key,
    required this.order,
    this.isUpdating = false,
    this.updatingAction,
    this.localEstado,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _expanded = false;

  static const Color _tasksColor = Color(0xFF0F6E56);

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusColor = _statusColor(order.estado);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXLarge),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: widget.isUpdating
          ? OrderUpdatingOverlay(
              action: widget.updatingAction ?? 'Actualizando...',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 4, child: ColoredBox(color: statusColor)),

                // ── Header ───────────────────────────────────────────────
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AppDimensions.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order.displayId,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.aloDarkBlue,
                                ),
                              ),
                              const Spacer(),
                              OrderPriorityBadge(priority: order.priorityLabel),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: _expanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: const Icon(
                                  Icons.expand_more,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            order.clientDisplayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.fullAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.technicianName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OrderStatusChip(
                                label: order.displayStatus,
                                color: statusColor,
                              ),
                            ],
                          ),
                          if (order.hasTasks) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.checklist_rtl_outlined,
                                  size: 14,
                                  color: _tasksColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    order.tasksPending > 0
                                        ? '${order.tasksPending} ${order.tasksPending == 1 ? 'tarea pendiente' : 'tareas pendientes'} de ${order.tasksTotal}'
                                        : '${order.tasksTotal} ${order.tasksTotal == 1 ? 'tarea' : 'tareas'} (todas terminadas)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _tasksColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: order.tasksDone / order.tasksTotal,
                                minHeight: 6,
                                backgroundColor: AppColors.divider,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Contenido expandible ─────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? _buildExpanded(context, order)
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
    );
  }

  Widget _buildExpanded(BuildContext context, OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        OrderExpandedContent(order: order),
        if (order.docEntry != null && order.docNum != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                foregroundColor: _tasksColor,
                side: BorderSide(color: _tasksColor.withValues(alpha: 0.4)),
              ),
            ),
          ),
        const Divider(height: 1),
        OrderActionButtons(order: order, localEstado: widget.localEstado),
      ],
    );
  }

  Color _statusColor(String? estado) {
    // Catálogo real de U_Estado de la OM (VID_MTOM): P/L/C/X.
    switch (estado?.toUpperCase().trim()) {
      case 'P':
        return AppColors.aloOrange; // Planificada
      case 'L':
        return const Color(0xFF2196F3); // Liberada
      case 'C':
        return AppColors.success; // Cerrada
      case 'X':
        return AppColors.error; // Cancelada
      default:
        return Colors.grey;
    }
  }
}