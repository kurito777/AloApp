import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../dashboard/presentation/widgets/order_badges.dart';
import '../../data/models/order_model.dart';
import 'om_card.dart';

/// Color asociado al estado de la OM (catálogo U_Estado: P/L/C/X).
Color omStatusColor(String? estado) {
  switch (estado?.toUpperCase().trim()) {
    case 'P':
      return AppColors.aloOrange;
    case 'L':
      return const Color(0xFF2196F3);
    case 'C':
      return AppColors.success;
    case 'X':
      return AppColors.error;
    default:
      return Colors.grey;
  }
}

/// Cabecera del detalle: número de OM, estado, prioridad, cliente y datos del
/// equipo, la dirección y el problema reportado.
class OmDetailHeader extends StatelessWidget {
  final OrderModel order;

  const OmDetailHeader({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = omStatusColor(order.estado);
    final hasEquipment =
        order.equipoDescripcion != null || order.equipoCode != null;

    return OmCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 4,
            child: ColoredBox(color: statusColor),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.displayId,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.aloDarkBlue,
                        ),
                      ),
                    ),
                    OrderPriorityBadge(priority: order.priorityLabel),
                  ],
                ),
                const SizedBox(height: 10),
                OrderStatusChip(
                  label: order.displayStatus,
                  color: statusColor,
                ),
                const SizedBox(height: 16),
                Text(
                  order.clientDisplayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                if (hasEquipment)
                  _InfoRow(
                    icon: Icons.precision_manufacturing_outlined,
                    text: order.equipoDescripcion ?? order.equipoCode!,
                  ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: order.fullAddress,
                ),
                if (order.tipoOM != null)
                  _InfoRow(
                    icon: Icons.build_outlined,
                    text: 'Tipo: ${order.tipoOM}',
                  ),
                if (order.descripcionProblema.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _ProblemBox(text: order.descripcionProblema),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemBox extends StatelessWidget {
  final String text;

  const _ProblemBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.aloOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.aloOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.report_problem_outlined,
            size: 18,
            color: AppColors.aloOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}