import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../widgets/ui_blocks.dart';

/// The one section label used across the Log screen.
///
/// There used to be three of these — the dashboard's, the meals list's, and the
/// cards' own titles — at three sizes and weights, which is most of why the
/// screen read as noisy. Everything above a section now goes through here.
class LogSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LogSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.42 : 0.45),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.3,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          AppScaleTap(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                actionLabel!,
                style: AppTypography.labelSmall.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
