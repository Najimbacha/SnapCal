import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/water_provider.dart';

class WaterTrackingCard extends StatelessWidget {
  const WaterTrackingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, waterProvider, child) {
        final amount = waterProvider.todaysWaterMl;
        final goal = 2000; // Default goal
        final progress = (amount / goal).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.droplets,
                        color: AppColors.carbs,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('Hydration', style: AppTypography.heading3),
                    ],
                  ),
                  Text(
                    '$amount / $goal ml',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.carbs,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.glassBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.carbs,
                ),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWaterActionButton(context, '+250ml', 250),
                  _buildWaterActionButton(context, '+500ml', 500),
                  _buildWaterActionButton(context, 'Custom', 0, isCustom: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaterActionButton(
    BuildContext context,
    String label,
    int amount, {
    bool isCustom = false,
  }) {
    return ElevatedButton(
      onPressed: () {
        if (isCustom) {
          _showCustomWaterDialog(context);
        } else {
          context.read<WaterProvider>().addWater(amount);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(80, 40),
        textStyle: AppTypography.labelSmall.copyWith(
          inherit: false, // Prevent interpolation issues
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }

  void _showCustomWaterDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Water'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: 'ml',
                hintText: 'Enter amount',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final val = int.tryParse(controller.text);
                  if (val != null) {
                    context.read<WaterProvider>().addWater(val);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }
}
