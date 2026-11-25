import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Pantalla de verificación de código OTP. Se muestra tras ingresar un correo
/// válido; el código llega al Google Sheet (y al correo en producción).
class OtpPage extends StatefulWidget {
  final String email;

  const OtpPage({super.key, required this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  late final AnimationController _shakeController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _verify() {
    final code = _ctrl.text.trim();
    if (code.length != 6) return;
    context.read<AuthBloc>().add(VerifyOtpRequested(code));
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading || state is AuthOtpVerifying) {
            _clearError();
          }

          if (state is AuthAuthenticated) {
            // Cierra esta pantalla; el login (debajo) redirige al dashboard.
            Navigator.of(context).pop();
          } else if (state is AuthOtpError) {
            _ctrl.clear();
            _showError(state.message);
          } else if (state is AuthOtpSent && state.resent) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Código reenviado.'),
              backgroundColor: AppColors.success,
            ));
          }
        },
        builder: (context, state) {
          final busy = state is AuthLoading || state is AuthOtpVerifying;

          return DecoratedBox(
            decoration: const BoxDecoration(
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -160,
                  right: -120,
                  child: IgnorePointer(
                    child: Container(
                      width: 480,
                      height: 480,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.aloYellow.withValues(alpha: 0.14),
                            AppColors.aloYellow.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLarge,
                        vertical: kToolbarHeight,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 24 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppDimensions.cardMaxWidth,
                          ),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadiusCircle,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(
                                  height: 6,
                                  child: ColoredBox(color: AppColors.aloYellow),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(
                                    AppDimensions.paddingXLarge,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: Hero(
                                          tag: 'auth-logo',
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: AppColors.aloYellow,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.aloYellow
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.mark_email_read_outlined,
                                              size: 40,
                                              color: AppColors.aloDarkBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppDimensions.paddingLarge,
                                      ),
                                      Text(
                                        'Verifica tu código',
                                        textAlign: TextAlign.center,
                                        style: textTheme.displayMedium?.copyWith(
                                          color: AppColors.aloDarkBlue,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppDimensions.paddingSmall,
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(
                                              text:
                                                  'Ingresa el código de 6 dígitos enviado a\n',
                                            ),
                                            TextSpan(
                                              text: widget.email,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.aloDarkBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppDimensions.paddingXLarge,
                                      ),
                                      AnimatedBuilder(
                                        animation: _shakeController,
                                        builder: (context, child) {
                                          final t = _shakeController.value;
                                          final dx = math.sin(t * math.pi * 6) *
                                              10 *
                                              (1 - t);
                                          return Transform.translate(
                                            offset: Offset(dx, 0),
                                            child: child,
                                          );
                                        },
                                        child: AppTextField(
                                          controller: _ctrl,
                                          enabled: !busy,
                                          autofocus: true,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          maxLength: 6,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            letterSpacing: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.aloDarkBlue,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          hintText: '______',
                                          onChanged: (_) {
                                            _clearError();
                                            setState(() {});
                                          },
                                          onSubmitted: (_) =>
                                              busy ? null : _verify(),
                                        ),
                                      ),
                                      AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        curve: Curves.easeOutCubic,
                                        alignment: Alignment.topCenter,
                                        child: _errorMessage == null
                                            ? const SizedBox(
                                                width: double.infinity,
                                              )
                                            : Padding(
                                                padding: const EdgeInsets.only(
                                                  top: AppDimensions
                                                      .paddingLarge,
                                                ),
                                                child: AppErrorBanner(
                                                  message: _errorMessage!,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(
                                        height: AppDimensions.paddingLarge,
                                      ),
                                      AppPrimaryButton(
                                        label: 'Verificar',
                                        icon: Icons.check_rounded,
                                        isLoading: busy,
                                        onPressed: (busy ||
                                                _ctrl.text.trim().length != 6)
                                            ? null
                                            : _verify,
                                      ),
                                      const SizedBox(
                                        height: AppDimensions.paddingMedium,
                                      ),
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: busy
                                              ? null
                                              : () => context
                                                  .read<AuthBloc>()
                                                  .add(
                                                    const ResendOtpRequested(),
                                                  ),
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Reenviar código'),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppColors.aloDarkBlue,
                                            textStyle: const TextStyle(
                                              fontSize:
                                                  AppDimensions.textMedium,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}