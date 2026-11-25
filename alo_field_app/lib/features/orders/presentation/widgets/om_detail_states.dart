import 'package:flutter/material.dart';

import '../../../../core/config/sap_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../data/models/order_model.dart';
import 'om_card.dart';

// ── Carga ────────────────────────────────────────────────────────────────

/// Esqueleto animado que imita la estructura del detalle mientras se carga.
class OmLoadingView extends StatelessWidget {
  const OmLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _Pulse(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _Block(width: 120, height: 24),
                        const Spacer(),
                        const _Block(width: 64, height: 20, radius: 6),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _Block(width: 96, height: 22, radius: 20),
                    const SizedBox(height: 18),
                    const _Block(width: 200, height: 18),
                    const SizedBox(height: 16),
                    const _Block(height: 14),
                    const SizedBox(height: 10),
                    const _Block(height: 14),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Block(width: 150, height: 18),
                    SizedBox(height: 16),
                    _Block(height: 14),
                    SizedBox(height: 12),
                    _Block(height: 14),
                    SizedBox(height: 12),
                    _Block(height: 14),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Block(width: 130, height: 18),
                    SizedBox(height: 16),
                    _Block(height: 14),
                    SizedBox(height: 12),
                    _Block(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Cargando OM...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Widget child;

  const _SkeletonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return OmCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _Block({this.width, required this.height, this.radius = 8});

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

class _Pulse extends StatefulWidget {
  final Widget child;

  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

// ── Error ────────────────────────────────────────────────────────────────

class OmErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const OmErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: AppPrimaryButton(
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Solo lectura ─────────────────────────────────────────────────────────

class OmReadOnlyBanner extends StatelessWidget {
  final OrderModel order;

  const OmReadOnlyBanner({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final estado = SapConfig.translateOmState(order.estado) ?? 'Cerrada';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE08A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 20, color: Color(0xFF8A6D00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'OM $estado — solo lectura. No se puede modificar en SAP.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF8A6D00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guardando ────────────────────────────────────────────────────────────

/// Capa que oscurece la pantalla y bloquea los toques mientras se escribe en
/// SAP.
class OmSavingOverlay extends StatelessWidget {
  const OmSavingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: AbsorbPointer(
        child: ColoredBox(
          color: const Color(0x33000000),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}