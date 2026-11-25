import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/main_navigation.dart';
import '../../../maps/presentation/bloc/maps_bloc.dart';
import '../../../maps/presentation/bloc/maps_event.dart';
import '../../../orders/data/models/order_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import 'order_badges.dart';

/// Acciones de una orden: ver ubicación y el botón del ciclo de la actividad.
class OrderActionButtons extends StatelessWidget {
  final OrderModel order;

  /// Estado local del ciclo (null = no iniciada; 'EC'/'EA'/'EP'/'F').
  final String? localEstado;

  const OrderActionButtons({super.key, required this.order, this.localEstado});

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
      cycleButton = _ActionButton(
        label: 'Iniciar',
        icon: Icons.play_arrow_rounded,
        color: AppColors.aloYellow,
        textColor: AppColors.aloDarkBlue,
        onPressed: () => bloc.add(
            InitiateOrder(docEntry: order.docEntry!, docNum: order.docNum!)),
      );
    } else if (local == 'EC') {
      cycleButton = _ActionButton(
        label: 'Llegué',
        icon: Icons.location_on,
        color: const Color(0xFF2196F3),
        textColor: Colors.white,
        onPressed: () => bloc.add(MarkOrderAsArrived(
            docEntry: order.docEntry!, docNum: order.docNum!)),
      );
    } else if (local == 'EA' || local == 'EP') {
      cycleButton = _ActionButton(
        label: 'Finalizar',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        textColor: Colors.white,
        onPressed: () => _showFinishDialog(context, bloc, order),
      );
    } else if (local == 'F') {
      cycleButton = const OrderDoneChip();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // "Ver ubicación": resuelve la obra (equipo→contrato→dirección) y
          // muestra el mapa. Disponible siempre que la OM tenga equipo.
          if (order.equipoCode != null)
            Expanded(
              child: _ActionButton(
                label: 'Ver ubicación',
                icon: Icons.place,
                color: AppColors.aloDarkBlue,
                textColor: Colors.white,
                onPressed: () => _navigateToObra(context, order),
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size(0, AppDimensions.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(
          fontSize: AppDimensions.textMedium,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        ),
      ),
    );
  }
}