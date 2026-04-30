import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/water_provider.dart';
import '../../../widgets/ui_blocks.dart';

class WaterTrackingCard extends StatefulWidget {
  const WaterTrackingCard({super.key});

  @override
  State<WaterTrackingCard> createState() => _WaterTrackingCardState();
}

class _WaterTrackingCardState extends State<WaterTrackingCard> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.carbs.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.carbs.withValues(alpha: 0.2)),
                ),
                child: const Icon(LucideIcons.droplets, color: AppColors.carbs, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hydration Tracker',
                      style: AppTypography.heading3.copyWith(
                        color: context.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$amount of $goal ml reached',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.carbs.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.carbs,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Liquid Water Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 12,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(color: context.dividerColor.withValues(alpha: 0.5)),
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      // Detect if we are hidden by a bottom nav tab switch
                      final tickerActive = TickerMode.of(context);
                      if (tickerActive != _waveController.isAnimating) {
                        if (tickerActive) {
                          _waveController.repeat();
                        } else {
                          _waveController.stop();
                        }
                      }
                      
                      return CustomPaint(
                        size: const Size(double.infinity, 12),
                        painter: _WaterWaveBarPainter(
                          animationValue: _waveController.value,
                          progress: progress,
                          color: AppColors.carbs,
                        ),
                      );
                    },
                  ),
                ],
              ),
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

class _WaterWaveBarPainter extends CustomPainter {
  final double animationValue;
  final double progress;
  final Color color;

  _WaterWaveBarPainter({
    required this.animationValue,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillWidth = size.width * progress;
    final path = Path();
    
    path.moveTo(0, size.height);
    
    // Wave at the top edge of the water bar
    for (double i = 0; i <= fillWidth; i++) {
      final double waveHeight = math.sin((i / 40) + (animationValue * 2 * math.pi)) * 3.0;
      path.lineTo(i, (size.height * 0.4) + waveHeight);
    }

    path.lineTo(fillWidth, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
    
    // Solid fill below the wave
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.5, fillWidth, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant _WaterWaveBarPainter oldDelegate) => 
    oldDelegate.animationValue != animationValue || 
    oldDelegate.progress != progress;
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
