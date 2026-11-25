import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Versión más oscura del color base, para que el texto se lea sobre fondos
/// suaves del mismo tono.
Color _readableTone(Color base, double amount) {
  return Color.lerp(base, AppColors.aloDarkBlue, amount)!;
}

/// Chip con el estado de la orden (Planificada, Liberada, Cerrada...).
class OrderStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const OrderStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _readableTone(color, 0.5),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Insignia de prioridad: Alta (rojo), Media (naranja) y el resto en neutro.
class OrderPriorityBadge extends StatelessWidget {
  final String priority;

  const OrderPriorityBadge({super.key, required this.priority});

  Color get _color {
    switch (priority) {
      case 'Alta':
        return AppColors.priorityHigh;
      case 'Media':
        return AppColors.priorityMedium;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _readableTone(color, 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip que reemplaza al botón de ciclo cuando la orden ya se finalizó.
class OrderDoneChip extends StatelessWidget {
  const OrderDoneChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            'Finalizada',
            style: TextStyle(
              color: _readableTone(AppColors.success, 0.35),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}