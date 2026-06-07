import 'package:flutter/material.dart';

import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.margin,
    this.onTap,
    this.color,
    this.radius = AppRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = colorScheme.outlineVariant.withValues(
      alpha: isDark ? 0.24 : 1,
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}
