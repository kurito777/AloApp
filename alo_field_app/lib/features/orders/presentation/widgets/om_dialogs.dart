import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import 'om_tasks_card.dart';

/// Confirmación para eliminar un elemento de la OM. Devuelve `true` si el
/// usuario confirma.
Future<bool> showOmConfirmDialog(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.errorSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          size: 28,
          color: AppColors.error,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Diálogo con un campo de texto validado. Devuelve el texto ingresado o
/// `null` si se cancela.
Future<String?> showOmPromptDialog({
  required BuildContext context,
  required String title,
  required String hint,
  required String? Function(String) validate,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _OmPromptDialog(
      title: title,
      hint: hint,
      validate: validate,
    ),
  );
}

class _OmPromptDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String? Function(String) validate;

  const _OmPromptDialog({
    required this.title,
    required this.hint,
    required this.validate,
  });

  @override
  State<_OmPromptDialog> createState() => _OmPromptDialogState();
}

class _OmPromptDialogState extends State<_OmPromptDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.validate(_ctrl.text);

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 2,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _ctrl.text.isEmpty ? null : error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed:
              error != null ? null : () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

/// Hoja inferior para elegir el estado de una tarea. Devuelve el código
/// elegido ('N', 'P' o 'T') o `null` si se cierra sin elegir.
Future<String?> showOmEstadoSheet({
  required BuildContext context,
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                'Estado de la tarea',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.aloDarkBlue,
                ),
              ),
            ),
            for (final e in const [
              ('N', 'No iniciada'),
              ('P', 'En proceso'),
              ('T', 'Terminada'),
            ])
              _EstadoOption(
                code: e.$1,
                label: e.$2,
                selected: current == e.$1,
                onTap: () => Navigator.pop(ctx, e.$1),
              ),
          ],
        ),
      ),
    ),
  );
}

class _EstadoOption extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EstadoOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (color, _, icon) = omTaskVisual(code);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.10)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : AppColors.divider,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                    color: AppColors.success,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}