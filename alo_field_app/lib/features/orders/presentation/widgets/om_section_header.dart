import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Encabezado de una sección de la OM: ícono, título y botón "Agregar".
class OmSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool showAdd;
  final VoidCallback? onAdd;

  const OmSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.showAdd,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.aloYellow.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.aloDarkBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.aloDarkBlue,
            ),
          ),
        ),
        if (showAdd) _AddButton(onPressed: onAdd),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Agregar'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textOnPrimary,
        backgroundColor: AppColors.aloYellow,
        disabledForegroundColor: AppColors.textHint,
        disabledBackgroundColor: AppColors.divider,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 40),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Mensaje para una sección sin elementos.
class OmEmptyNote extends StatelessWidget {
  final String text;

  const OmEmptyNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.3,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}