import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/ui_blocks.dart';

class MacroCard extends StatelessWidget {
  final String label;
  final int consumed;
  final int goal;
  final Color color;
  final IconData? icon;

  const MacroCard({
    super.key,
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: AppSectionCard(
        color: context.cardSoftColor,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon ?? Icons.circle, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: AppTypography.labelSmall.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${consumed}g',
              style: AppTypography.heading2.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$label • $goal g goal',
              style: AppTypography.bodySmall.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: progress,
                backgroundColor: context.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
