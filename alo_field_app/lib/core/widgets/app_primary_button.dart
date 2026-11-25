import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _interactive => widget.onPressed != null && !widget.isLoading;
  bool get _faded => widget.onPressed == null && !widget.isLoading;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lifted = _interactive && _hovered;

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.label,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _interactive,
        mouseCursor:
            _interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _interactive ? (_) => _setPressed(true) : null,
          onTapUp: _interactive ? (_) => _setPressed(false) : null,
          onTapCancel: _interactive ? () => _setPressed(false) : null,
          onTap: _interactive ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _faded ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: AppDimensions.buttonHeightLarge,
                alignment: Alignment.center,
                transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusLarge,
                  ),
                  border: Border.all(
                    color: _focused ? AppColors.aloBlack : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: _faded
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.aloOrange
                                .withValues(alpha: lifted ? 0.55 : 0.30),
                            blurRadius: lifted ? 22 : 14,
                            offset: Offset(0, lifted ? 10 : 6),
                          ),
                        ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: widget.isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : Row(
                          key: const ValueKey('label'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: const TextStyle(
                                fontSize: AppDimensions.textLarge,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                            if (widget.icon != null) ...[
                              const SizedBox(width: AppDimensions.paddingSmall),
                              AnimatedSlide(
                                offset: Offset(lifted ? 0.25 : 0, 0),
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: Icon(
                                  widget.icon,
                                  size: 20,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}