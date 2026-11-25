import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

/// Barra de búsqueda integrada con el encabezado oscuro del dashboard.
class DashboardSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const DashboardSearchBar({super.key, required this.controller});

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXLarge),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            cursorColor: AppColors.aloYellow,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppDimensions.textLarge,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar OM, cliente, equipo...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white60,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                      ),
                      tooltip: 'Limpiar búsqueda',
                      onPressed: controller.clear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: _border(Colors.white.withValues(alpha: 0.10)),
              enabledBorder: _border(Colors.white.withValues(alpha: 0.10)),
              focusedBorder: _border(AppColors.aloYellow, width: 1.5),
            ),
          );
        },
      ),
    );
  }
}

/// Filtros por el ciclo real de la actividad (estado local de cada OM).
class DashboardStatusFilterBar extends StatelessWidget {
  const DashboardStatusFilterBar({super.key});

  static const List<(String, String?, IconData)> _filters = [
    ('Todas', null, Icons.apps_rounded),
    ('Sin iniciar', 'NEW', Icons.hourglass_empty_rounded),
    ('En curso', 'INPROGRESS', Icons.play_circle_outline_rounded),
    ('Finalizadas', 'DONE', Icons.check_circle_outline_rounded),
  ];

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
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              for (final f in _filters)
                _FilterChipItem(
                  label: f.$1,
                  sapCode: f.$2,
                  icon: f.$3,
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
  final IconData icon;
  final String? currentFilter;

  const _FilterChipItem({
    required this.label,
    required this.sapCode,
    required this.icon,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentFilter == sapCode;
    final contentColor =
        isSelected ? AppColors.aloDarkBlue : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: contentColor),
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => context
            .read<DashboardBloc>()
            .add(FilterOrdersByStatus(sapCode)),
        selectedColor: AppColors.aloYellow,
        backgroundColor: AppColors.surface,
        side: BorderSide(
          color: isSelected ? AppColors.aloYellow : AppColors.border,
        ),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          fontSize: 13,
          color: contentColor,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}