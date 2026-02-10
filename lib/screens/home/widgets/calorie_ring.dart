import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/glass_container.dart';

/// Ultra-premium circular progress indicator for calorie tracking
class CalorieRing extends StatelessWidget {
  final int consumed;
  final int goal;
  final double size;

  const CalorieRing({
    super.key,
    required this.consumed,
    required this.goal,
    this.size = 250,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = goal - consumed;
    final isOver = remaining < 0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Interactive Glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isOver ? AppColors.error : AppColors.primary)
                      .withOpacity(0.12),
                  blurRadius: 100,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Main Ring Container
          CustomPaint(
            size: Size(size, size),
            painter: _PremiumRingPainter(
              progress: progress,
              trackColor: context.surfaceLightColor.withOpacity(0.1),
              activeGradient:
                  isOver
                      ? const LinearGradient(
                        colors: [AppColors.error, Color(0xFFFF8A80)],
                      )
                      : AppColors.primaryGradient,
              strokeWidth: 22, // Slightly bolder for premium feel
            ),
          ),

          // Central Glass Card
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.labelSmall.copyWith(
                  color: isOver ? AppColors.error : AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                consumed.toString(),
                style: AppTypography.displayLarge.copyWith(
                  color: context.textPrimaryColor,
                  fontSize: 64,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -3,
                ),
              ),
              Text(
                'KCAL EATEN',
                style: AppTypography.labelSmall.copyWith(
                  color: context.textMutedColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                borderRadius: 22,
                backgroundColor: context.surfaceColor.withOpacity(0.6),
                borderColor: (isOver ? AppColors.error : AppColors.primary)
                    .withOpacity(0.2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOver ? Icons.warning_rounded : Icons.flash_on_rounded,
                      size: 14,
                      color: isOver ? AppColors.error : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOver
                          ? '${remaining.abs()} over goal'
                          : '$remaining kcal left',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isOver ? AppColors.error : context.textPrimaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Gradient activeGradient;
  final double strokeWidth;

  _PremiumRingPainter({
    required this.progress,
    required this.trackColor,
    required this.activeGradient,
    required this.strokeWidth,
  });

  // Reusable paint to keep it fast
  static final Paint _paint =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

  static final Paint _glowPaint =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          10,
        ); // Reduced blur

  static final Paint _highlightPaint =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw Track
    _paint.shader = null;
    _paint.color = trackColor;
    _paint.strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, _paint);

    if (progress <= 0) return;

    // 2. Draw Outer Glow for Active Ring
    _glowPaint.strokeWidth = strokeWidth + 4;
    _glowPaint.shader = activeGradient.createShader(rect);
    _glowPaint.color = Colors.white;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      _glowPaint,
    );

    // 3. Draw Main Active Progress Ring
    _paint.strokeWidth = strokeWidth;
    _paint.shader = activeGradient.createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, _paint);

    // 4. Draw "Highlight" on Active Ring (Top Gloss)
    _highlightPaint.strokeWidth = strokeWidth / 3;
    _highlightPaint.shader = LinearGradient(
      colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      _highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_PremiumRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeGradient != activeGradient;
  }
}
