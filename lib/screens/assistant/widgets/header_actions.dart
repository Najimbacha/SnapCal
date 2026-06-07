import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/app_icon.dart';

/// Three minimal icon buttons in the screen header.
///
/// Visual rules:
/// - 36×36 circle, subtle tinted background
/// - No heavy border; uses an alpha overlay to sit on the page
/// - Subtle press animation (scale to 0.92)
class AssistantHeaderActions extends StatelessWidget {
  final VoidCallback onWeeklyReport;
  final VoidCallback onOpenProfile;
  final VoidCallback onNewChat;
  final bool isPro;
  final bool hasActiveThread;

  const AssistantHeaderActions({
    super.key,
    required this.onWeeklyReport,
    required this.onOpenProfile,
    required this.onNewChat,
    required this.isPro,
    required this.hasActiveThread,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: AppSymbols.barChart3,
          tooltip: 'Weekly report',
          onTap: onWeeklyReport,
          tint: tint,
          badge: !isPro
              ? const _ProBadge()
              : null,
        ),
        const SizedBox(width: 6),
        _ActionButton(
          icon: AppSymbols.user,
          tooltip: 'Coach profile',
          onTap: onOpenProfile,
          tint: tint,
        ),
        const SizedBox(width: 6),
        _ActionButton(
          icon: AppSymbols.add,
          tooltip: 'New conversation',
          onTap: onNewChat,
          tint: hasActiveThread
              ? AppColors.homeCoachAccent.withValues(alpha: 0.12)
              : tint,
          iconColor: hasActiveThread
              ? AppColors.homeCoachAccent
              : null,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color tint;
  final Color? iconColor;
  final Widget? badge;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.tint,
    this.iconColor,
    this.badge,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.tint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: widget.iconColor ?? context.textPrimaryColor,
                ),
              ),
              if (widget.badge != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: widget.badge!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.premiumGold,
        shape: BoxShape.circle,
        border: Border.all(color: context.surfaceColor, width: 1.5),
      ),
      child: const Icon(
        AppSymbols.lock,
        size: 7,
        color: Colors.black,
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
          duration: 1800.ms,
          begin: 1,
          end: 1.12,
        );
  }
}
