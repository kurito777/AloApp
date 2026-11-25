import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_primary_button.dart';

/// Vista de carga: tarjetas esqueleto mientras llegan las órdenes desde SAP.
class DashboardLoadingView extends StatefulWidget {
  const DashboardLoadingView({super.key});

  @override
  State<DashboardLoadingView> createState() => _DashboardLoadingViewState();
}

class _DashboardLoadingViewState extends State<DashboardLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.aloDarkBlue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando órdenes desde SAP...',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        FadeTransition(
          opacity: _pulse,
          child: const Column(
            children: [
              _SkeletonCard(),
              _SkeletonCard(),
              _SkeletonCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXLarge),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBar(width: 12, height: 12, radius: 6),
              SizedBox(width: 8),
              _SkeletonBar(width: 90, height: 18),
              Spacer(),
              _SkeletonBar(width: 56, height: 20),
            ],
          ),
          SizedBox(height: 14),
          FractionallySizedBox(
            widthFactor: 0.6,
            child: _SkeletonBar(height: 16),
          ),
          SizedBox(height: 10),
          FractionallySizedBox(
            widthFactor: 0.85,
            child: _SkeletonBar(height: 12),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              _SkeletonBar(width: 110, height: 12),
              Spacer(),
              _SkeletonBar(width: 72, height: 22, radius: 11),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBar({this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Vista cuando no hay órdenes para los filtros actuales.
class DashboardEmptyView extends StatelessWidget {
  final String reason;

  const DashboardEmptyView({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _StateIconTile(
              icon: Icons.inbox_outlined,
              iconColor: AppColors.textSecondary,
              background: AppColors.infoSoft,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text(
              'Sin órdenes',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.aloDarkBlue,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                reason,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de error al cargar las órdenes, con opción de reintentar.
class DashboardErrorView extends StatelessWidget {
  final String message;
  final bool canRetry;
  final VoidCallback onRetry;

  const DashboardErrorView({
    super.key,
    required this.message,
    required this.canRetry,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _StateIconTile(
              icon: Icons.cloud_off_outlined,
              iconColor: AppColors.error,
              background: AppColors.errorSoft,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Text(
              'Error al cargar',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.aloDarkBlue,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (canRetry) ...[
              const SizedBox(height: AppDimensions.paddingLarge),
              SizedBox(
                width: 220,
                child: AppPrimaryButton(
                  label: 'Reintentar',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Se muestra dentro de la tarjeta mientras se actualiza una orden en SAP.
class OrderUpdatingOverlay extends StatelessWidget {
  final String action;

  const OrderUpdatingOverlay({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 96,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.aloDarkBlue,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                action,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateIconTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;

  const _StateIconTile({
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 44, color: iconColor),
    );
  }
}