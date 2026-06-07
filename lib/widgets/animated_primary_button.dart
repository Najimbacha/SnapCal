import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme_extensions.dart';
import '../core/theme/app_typography.dart';
import 'app_icon.dart';

class AnimatedPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final bool premium;
  final double height;

  const AnimatedPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.premium = false,
    this.height = 50,
  });

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final gradient =
        widget.premium ? context.snapcalTheme.premiumGradient : null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp:
          enabled
              ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
              : null,
      child: AnimatedScale(
        duration: AppMotion.instant,
        curve: AppMotion.standardCurve,
        scale: _pressed ? 0.98 : 1,
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.standardCurve,
          height: widget.height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color:
                gradient == null
                    ? (enabled
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest)
                    : null,
            gradient: enabled ? gradient : null,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.standard,
            switchInCurve: AppMotion.standardCurve,
            switchOutCurve: AppMotion.exitCurve,
            child:
                widget.isLoading
                    ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : widget.isSuccess
                    ? const AppIcon(
                      AppSymbols.success,
                      key: ValueKey('success'),
                      color: Colors.white,
                      filled: true,
                    )
                    : Text(
                      widget.label,
                      key: const ValueKey('label'),
                      style: AppTypography.labelLarge.copyWith(
                        color:
                            enabled
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
