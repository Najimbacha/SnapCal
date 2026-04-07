import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/water_provider.dart';
import '../../../widgets/ui_blocks.dart';

class WaterTrackingCard extends StatelessWidget {
  const WaterTrackingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final amount = context.select<WaterProvider, int>((p) => p.todaysWaterMl);
    const goal = 2000;
    final progress = (amount / goal).clamp(0.0, 1.0);

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(title: 'Hydration'),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.carbs.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.droplets, color: AppColors.carbs),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Water intake',
                      style: AppTypography.heading3.copyWith(
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      '$amount of $goal ml',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.heading3.copyWith(color: AppColors.carbs),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: context.dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.carbs),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _WaterButton(label: '+250 ml', amount: 250),
              _WaterButton(label: '+500 ml', amount: 500),
              _WaterButton(label: 'Custom', amount: 0, isCustom: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final String label;
  final int amount;
  final bool isCustom;

  const _WaterButton({
    required this.label,
    required this.amount,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChipButton(
      icon: isCustom ? LucideIcons.plus : LucideIcons.droplets,
      label: label,
      onTap: () {
        HapticFeedback.lightImpact();
        if (isCustom) {
          _showCustomWaterDialog(context);
        } else {
          context.read<WaterProvider>().addWater(amount);
        }
      },
    );
  }

  void _showCustomWaterDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Water'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter amount',
              suffixText: 'ml',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  context.read<WaterProvider>().addWater(value);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
