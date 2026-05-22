import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/theme_colors.dart';
import '../core/utils/responsive_utils.dart';

class AppSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool glass;

  final EdgeInsetsGeometry? margin;

  const AppSectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hPadding = Responsive.hPadding(context);
    final vPadding = Responsive.vPadding(context);
    final resolvedPadding =
        padding ??
        EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding);
    final radius = BorderRadius.circular(22);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final decoration = BoxDecoration(
      color:
          color ??
          (glass
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.65))
              : colorScheme.surfaceContainer),
      borderRadius: radius,
      border: Border.all(
        color: glass
            ? colorScheme.outlineVariant.withValues(alpha: 0.24)
            : (isDark
                ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                : AppColors.lightCardBorder),
        width: glass ? 1.5 : 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: isDark ? 0.18 : 0.06,
          ),
          blurRadius: glass ? 22 : 14,
          offset: const Offset(0, 10),
        ),
        // Subtle accent glow
        if (!glass)
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.04 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, -2),
          ),
      ],
    );

    Widget cardContent = ClipRRect(
      borderRadius: radius,
      child: Padding(padding: resolvedPadding, child: child),
    );

    if (glass) {
      cardContent = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ColorFilter.mode(
            colorScheme.surface.withValues(alpha: 0.1),
            BlendMode.srcOver,
          ),
          child: Padding(padding: resolvedPadding, child: child),
        ),
      );
    }

    final card = Container(
      margin: margin,
      decoration: decoration,
      child: cardContent,
    );

    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: radius, child: card);
  }
}

class SectionLabel extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  const SectionLabel({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Accent dash — premium detail
        Container(
          width: 3,
          height: 12,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          title.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: context.textMutedColor,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        const Spacer(),
        if (action != null && onActionTap != null)
          TextButton(onPressed: onActionTap, child: Text(action!)),
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final Color accent;
  final IconData icon;
  final VoidCallback? onTap;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              if (hint != null)
                Text(
                  hint!,
                  style: AppTypography.labelSmall.copyWith(
                    color: accent.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTypography.heading2.copyWith(
              fontWeight: FontWeight.w900,
              color: context.textPrimaryColor,
              letterSpacing: -1,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return AppScaleTap(onTap: onTap!, child: content);
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primaryColor.withValues(alpha: 0.15),
                      context.primaryColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(icon, size: 48, color: context.primaryColor),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 3.seconds,
                color: Colors.white.withValues(alpha: 0.2),
              ),
          const SizedBox(height: 32),
          Text(
            title,
            style: AppTypography.heading2.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 40),
            AppScaleTap(
              onTap: onAction!,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  actionLabel!,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark 
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark 
                ? colorScheme.primary.withValues(alpha: 0.15)
                : AppColors.lightCardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.04 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<AppScaleTap> createState() => _AppScaleTapState();
}

class AppAnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AppAnimatedPressable({super.key, required this.child, this.onTap});

  @override
  State<AppAnimatedPressable> createState() => _AppAnimatedPressableState();
}

class _AppAnimatedPressableState extends State<AppAnimatedPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.86 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

class _AppScaleTapState extends State<AppScaleTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (widget.onTap != null || widget.onLongPress != null) {
          _controller.forward();
        }
      },
      onTapUp: (_) {
        _controller.reverse();
      },
      onTap: widget.onTap,
      onTapCancel: () => _controller.reverse(),
      onLongPress: () {
        _controller.reverse();
        widget.onLongPress?.call();
      },
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const BottomActionBar({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}

class AppPulse extends StatefulWidget {
  final Widget child;
  final bool pulsing;

  const AppPulse({super.key, required this.child, this.pulsing = true});

  @override
  State<AppPulse> createState() => _AppPulseState();
}

class _AppPulseState extends State<AppPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulsing) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
