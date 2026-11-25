import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';
import 'om_card.dart';
import 'om_section_header.dart';

/// Color, etiqueta e ícono de una tarea según su estado (N / P / T).
(Color, String, IconData) omTaskVisual(String est) {
  switch (est) {
    case 'P':
      return (const Color(0xFF2196F3), 'En proceso', Icons.timelapse);
    case 'T':
      return (AppColors.success, 'Terminada', Icons.check_circle);
    default:
      return (
        AppColors.aloOrange,
        'No iniciada',
        Icons.radio_button_unchecked,
      );
  }
}

/// Tarjeta con el avance y la lista de tareas de la OM.
class OmTasksCard extends StatelessWidget {
  final OrderModel order;
  final bool editable;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<OrderTask> onPickEstado;
  final ValueChanged<OrderTask> onDelete;

  const OmTasksCard({
    super.key,
    required this.order,
    required this.editable,
    required this.busy,
    required this.onAdd,
    required this.onPickEstado,
    required this.onDelete,
  });

  List<Widget> _tiles() {
    final tiles = <Widget>[];
    for (var i = 0; i < order.tasks.length; i++) {
      if (i > 0) {
        tiles.add(const Divider(height: 1, color: AppColors.divider));
      }
      tiles.add(
        _TaskTile(
          task: order.tasks[i],
          editable: editable,
          busy: busy,
          onPickEstado: onPickEstado,
          onDelete: onDelete,
        ),
      );
    }
    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    return OmCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OmSectionHeader(
              icon: Icons.checklist_rtl_outlined,
              title: 'Tareas (${order.tasksPending} pend. / ${order.tasksTotal})',
              showAdd: editable,
              onAdd: busy ? null : onAdd,
            ),
            if (order.hasTasks) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: order.tasksDone / order.tasksTotal,
                  ),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: AppColors.divider,
                      color: AppColors.success,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (order.tasks.isEmpty)
              const OmEmptyNote(text: 'La OM no tiene tareas. Agrega la primera.')
            else
              ..._tiles(),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final OrderTask task;
  final bool editable;
  final bool busy;
  final ValueChanged<OrderTask> onPickEstado;
  final ValueChanged<OrderTask> onDelete;

  const _TaskTile({
    required this.task,
    required this.editable,
    required this.busy,
    required this.onPickEstado,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final est = (task.estado ?? 'N').toUpperCase();
    final (color, label, icon) = omTaskVisual(est);
    final done = est == 'T';
    final labelColor = Color.lerp(color, AppColors.aloDarkBlue, 0.4)!;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (busy || !editable) ? null : () => onPickEstado(task),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    icon,
                    key: ValueKey<String>(est),
                    size: 22,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.displayName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: done
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (editable) ...[
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 2),
                IconButton(
                  onPressed: busy ? null : () => onDelete(task),
                  color: AppColors.error,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 22),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}