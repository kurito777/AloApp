import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../orders/data/models/order_model.dart';

/// Detalle que se muestra al expandir una orden: datos de la OM, tareas,
/// repuestos y descripción del problema.
class OrderExpandedContent extends StatelessWidget {
  final OrderModel order;

  const OrderExpandedContent({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
            const SizedBox(height: 6),
            _SectionTitle(
              icon: Icons.checklist_rtl_outlined,
              text:
                  'Tareas: ${order.tasksPending} ${order.tasksPending == 1 ? 'pendiente' : 'pendientes'} de ${order.tasksTotal}',
            ),
            const SizedBox(height: 10),
            ...order.tasks.map((t) => _TaskRow(task: t)),
          ],

          // Materiales / repuestos
          if (order.visibleMaterials.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SectionTitle(
              icon: Icons.build_circle_outlined,
              text: 'Repuestos (${order.materialCount})',
            ),
            const SizedBox(height: 10),
            ...order.visibleMaterials.map((line) => _MaterialRow(line: line)),
          ],

          // Comentarios del técnico
          if (order.descripcionProblema.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descripción del problema:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.descripcionProblema,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
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

Color _readableTone(Color base, double amount) {
  return Color.lerp(base, AppColors.aloDarkBlue, amount)!;
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.aloDarkBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ],
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
    final accent = pending ? AppColors.aloOrange : AppColors.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            pending ? Icons.radio_button_unchecked : Icons.check_circle,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: pending ? AppColors.textPrimary : AppColors.textHint,
                    decoration: pending ? null : TextDecoration.lineThrough,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            task.statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _readableTone(accent, 0.4),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              line.itemDescription ?? line.itemCode ?? 'Item desconocido',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'x${line.quantity?.toStringAsFixed(0) ?? '1'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}