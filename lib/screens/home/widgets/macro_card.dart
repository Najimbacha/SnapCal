import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/glass_card.dart';

/// Card for displaying macro nutrient progress
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
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$consumed/${goal}g',
              style: AppTypography.labelLarge.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              padding: EdgeInsets.zero,
              lineHeight: 6,
              percent: progress,
              barRadius: const Radius.circular(3),
              backgroundColor: context.surfaceLightColor,
              progressColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
