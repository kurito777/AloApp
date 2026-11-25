import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  late final AnimationController _shakeController;
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  bool _otpOpen = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    emailController.dispose();
    _shakeController.dispose();
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _submit() {
    context
        .read<AuthBloc>()
        .add(LoginRequested(email: emailController.text.trim()));
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    _shakeController.forward(from: 0);
  }

  void _clearError() {
    if (_errorMessage == null) return;
    setState(() => _errorMessage = null);
  }

  Route<void> _otpRoute(AuthBloc authBloc, String email) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return BlocProvider.value(
          value: authBloc,
          child: OtpPage(email: email),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildCard(bool isLoading) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusCircle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: AppColors.aloOrange.withValues(alpha: 0.10),
            blurRadius: 64,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.brandGradient),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final t = _shakeController.value;
                    final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: AppTextField(
                    controller: emailController,
                    labelText: 'Correo corporativo',
                    hintText: 'usuario@alo-group.com',
                    prefixIcon: Icons.email_outlined,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (_) => _clearError(),
                    onSubmitted: (_) => isLoading ? null : _submit(),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _errorMessage == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: AppDimensions.paddingLarge,
                          ),
                          child: AppErrorBanner(message: _errorMessage!),
                        ),
                ),
                const SizedBox(height: AppDimensions.paddingLarge),
                AppPrimaryButton(
                  label: 'Ingresar',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainBadge(TextTheme textTheme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: AppDimensions.iconSmall,
              color: AppColors.textOnDarkMuted,
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            Flexible(
              child: Text(
                'Solo usuarios @alo-group.com',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.secondaryDark,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthLoading) {
            _clearError();
          }

          if (state is AuthAuthenticated) {
            context.go('/dashboard');
          }

          // Correo válido → abre la pantalla de código (una sola vez).
          if (state is AuthOtpSent && !_otpOpen) {
            _otpOpen = true;
            await Navigator.of(context).push(
              _otpRoute(context.read<AuthBloc>(), state.email),
            );
            _otpOpen = false;
          }

          if (state is AuthNotRegistered) {
            _showError(
              'El correo ${state.email} no está registrado como técnico.',
            );
          }

          if (state is AuthError) {
            _showError(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            fit: StackFit.expand,
            children: [
              _AmbientBackground(animation: _ambientController),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;

                    final form = ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppDimensions.cardMaxWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Reveal(
                            animation: _entranceController,
                            begin: 0.25,
                            end: 0.85,
                            child: _buildCard(isLoading),
                          ),
                          const SizedBox(height: 20),
                          _Reveal(
                            animation: _entranceController,
                            begin: 0.55,
                            end: 1,
                            dy: 12,
                            child: _buildDomainBadge(textTheme),
                          ),
                        ],
                      ),
                    );

                    final Widget content;
                    if (wide) {
                      content = ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _Reveal(
                                    animation: _entranceController,
                                    begin: 0,
                                    end: 0.6,
                                    child: const _BrandLockup(
                                      centered: false,
                                      large: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                0,
                                AppDimensions.paddingLarge,
                                48,
                                AppDimensions.paddingLarge,
                              ),
                              child: form,
                            ),
                          ],
                        ),
                      );
                    } else {
                      content = Padding(
                        padding:
                            const EdgeInsets.all(AppDimensions.paddingLarge),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Reveal(
                              animation: _entranceController,
                              begin: 0,
                              end: 0.6,
                              child: const _BrandLockup(
                                centered: true,
                                large: false,
                              ),
                            ),
                            const SizedBox(height: 36),
                            form,
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(child: content),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.centered, required this.large});

  final bool centered;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final alignment =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    final logoSize = large ? 96.0 : 80.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Hero(
          tag: 'auth-logo',
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(large ? 26 : 22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.aloOrange.withValues(alpha: 0.45),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Icon(
              Icons.engineering,
              size: large ? 54 : 44,
              color: AppColors.aloBlack,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingLarge),
        Text(
          'ALO Field',
          textAlign: textAlign,
          style: textTheme.displayLarge?.copyWith(
            fontSize: large ? 52 : AppDimensions.textDisplay,
            color: AppColors.textOnDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Gestión Técnica en Terreno',
          textAlign: textAlign,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
      ],
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.begin,
    required this.end,
    required this.child,
    this.dy = 24,
  });

  final Animation<double> animation;
  final double begin;
  final double end;
  final double dy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curve = Interval(begin, end, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final v = curve.transform(animation.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, dy * (1 - v)),
            child: child,
          ),
        );
      },
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.animation});

  final Animation<double> animation;

  Widget _orb({
    required double size,
    required Color color,
    required double alpha,
    required Offset shift,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Transform.translate(
          offset: shift,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: alpha),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surfaceDarkElevated,
                  AppColors.secondary,
                  AppColors.secondaryDark,
                ],
              ),
            ),
          ),
          const IgnorePointer(
            child: CustomPaint(painter: _DotGridPainter()),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    AppColors.secondaryDark.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = animation.value * 2 * math.pi;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _orb(
                    top: -180,
                    right: -140,
                    size: 560,
                    color: AppColors.aloOrange,
                    alpha: 0.32,
                    shift: Offset(math.sin(t) * 36, math.cos(t) * 28),
                  ),
                  _orb(
                    bottom: -200,
                    left: -160,
                    size: 520,
                    color: AppColors.aloRed,
                    alpha: 0.24,
                    shift: Offset(math.cos(t) * 30, math.sin(t) * 34),
                  ),
                  _orb(
                    bottom: -120,
                    right: 80,
                    size: 340,
                    color: AppColors.aloOrange,
                    alpha: 0.16,
                    shift: Offset(-math.sin(t) * 24, math.cos(t) * 20),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    for (double y = 14; y < size.height; y += 28) {
      for (double x = 14; x < size.width; x += 28) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}