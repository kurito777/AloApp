import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Contenedor base de las secciones de la OM: fondo blanco, borde fino y
/// sombra suave.
class OmCard extends StatelessWidget {
  final Widget child;

  const OmCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Entrada suave (desvanecer y subir) con un retraso opcional, para que las
/// secciones aparezcan una tras otra.
class OmEntrance extends StatelessWidget {
  final int delayMs;
  final Widget child;

  const OmEntrance({super.key, this.delayMs = 0, required this.child});

  @override
  Widget build(BuildContext context) {
    final total = 450 + delayMs;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}