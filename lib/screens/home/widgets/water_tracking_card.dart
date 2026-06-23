import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/water_provider.dart';
import '../../../widgets/ui_blocks.dart';
import 'package:go_router/go_router.dart';

class WaterTrackingCard extends ConsumerStatefulWidget {
  const WaterTrackingCard({super.key});

  @override
  ConsumerState<WaterTrackingCard> createState() => _WaterTrackingCardState();
}

class _WaterTrackingCardState extends ConsumerState<WaterTrackingCard>
    with SingleTickerProviderStateMixin {
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
    final amount = ref.watch(waterProvider).valueOrNull?.todayTotal ?? 0;
    const goal = 2000;
    final progress = (amount / goal).clamp(0.0, 1.0);

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title: AppLocalizations.of(context)!.water_hydration),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.carbs.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.carbs.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  LucideIcons.droplets,
                  color: AppColors.carbs,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.water_tracker,
                      style: AppTypography.heading3.copyWith(
                        color: context.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.water_reached(amount, goal),
                      style: AppTypography.bodySmall.copyWith(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                      final tickerActive = TickerMode.valuesOf(context).enabled;
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
          GestureDetector(
            onTap: () => context.push('/water'),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.85),
                    const Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.droplets, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Log Water',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$amount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'ml',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final fillWidth = size.width * progress;
    final path = Path();

    path.moveTo(0, size.height);

    // Wave at the top edge of the water bar
    for (double i = 0; i <= fillWidth; i++) {
      final double waveHeight =
          math.sin((i / 40) + (animationValue * 2 * math.pi)) * 3.0;
      path.lineTo(i, (size.height * 0.4) + waveHeight);
    }

    path.lineTo(fillWidth, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Solid fill below the wave
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.5, fillWidth, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterWaveBarPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.progress != progress;
}





