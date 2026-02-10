import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/water_provider.dart';
import '../../../widgets/glass_container.dart';

class WaterTrackingCard extends StatelessWidget {
  const WaterTrackingCard({super.key});

  @override
  Widget build(BuildContext context) {
    // High-performance granular selection
    final amount = context.select<WaterProvider, int>((p) => p.todaysWaterMl);
    const int goal = 2000; // Const goal for optimization
    final progress = (amount / goal).clamp(0.0, 1.0);

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      backgroundColor: context.surfaceColor.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.carbs.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.droplets,
                      color: AppColors.carbs,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HYDRATION',
                        style: AppTypography.labelSmall.copyWith(
                          color: context.textMutedColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'Daily Water Goal',
                        style: AppTypography.heading3.copyWith(
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amount',
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.carbs,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'of $goal ml',
                    style: AppTypography.labelSmall.copyWith(
                      color: context.textMutedColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.surfaceLightColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.carbs,
                        AppColors.carbs.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.carbs.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildWaterActionButton(context, '+250', 250)),
              const SizedBox(width: 12),
              Expanded(child: _buildWaterActionButton(context, '+500', 500)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWaterActionButton(
                  context,
                  'Custom',
                  0,
                  isCustom: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterActionButton(
    BuildContext context,
    String label,
    int amount, {
    bool isCustom = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isCustom) {
          _showCustomWaterDialog(context);
        } else {
          context.read<WaterProvider>().addWater(amount);
        }
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 12),
        borderRadius: 16,
        backgroundColor: context.surfaceLightColor.withOpacity(0.4),
        borderColor: context.glassBorderColor.withOpacity(0.4),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomWaterDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: context.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Add Water',
              style: AppTypography.heading3.copyWith(
                color: context.textPrimaryColor,
              ),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                suffixText: 'ml',
                suffixStyle: TextStyle(color: context.textSecondaryColor),
                hintText: 'Enter amount',
                hintStyle: TextStyle(color: context.textMutedColor),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.carbs),
                ),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: context.textSecondaryColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final val = int.tryParse(controller.text);
                  if (val != null) {
                    context.read<WaterProvider>().addWater(val);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.carbs,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }
}
