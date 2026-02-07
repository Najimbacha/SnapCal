import 'package:flutter/material.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/glass_container.dart';

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
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 24,
        backgroundColor: context.surfaceColor.withOpacity(0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon ?? _getIconForLabel(label),
                    size: 14,
                    color: color,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: context.textMutedColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  consumed.toString(),
                  style: AppTypography.heading3.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ' / ${goal}g',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.surfaceLightColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'protein':
        return Icons.fitness_center;
      case 'carbs':
        return Icons.bakery_dining;
      case 'fat':
        return Icons.opacity;
      default:
        return Icons.circle;
    }
  }
}
