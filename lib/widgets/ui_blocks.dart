import 'package:flutter/material.dart';


import '../core/theme/app_typography.dart';
import '../core/theme/theme_colors.dart';

class AppSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: card,
    );
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
        Text(
          title.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: context.textMutedColor,
            letterSpacing: 1.1,
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

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AppSectionCard(
      padding: const EdgeInsets.all(20),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: ShapeDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;
    return AppSectionCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 32),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTypography.heading3.copyWith(
              color: context.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardSoftColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  final Widget child;

  const BottomActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.overlayColor,
        border: Border(top: BorderSide(color: context.dividerColor)),
      ),
      child: child,
    );
  }
}
