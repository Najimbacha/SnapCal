import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/glass_container.dart';

/// Large circular progress indicator for calorie tracking
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

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),

          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: 1.0,
                color: context.surfaceColor.withOpacity(0.1),
                strokeWidth: 14,
              ),
            ),
          ),

          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                gradient: AppColors.primaryGradient,
                strokeWidth: 14,
                hasGlow: true,
              ),
            ),
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                consumed.toString(),
                style: AppTypography.displayLarge.copyWith(
                  color: context.textPrimaryColor,
                  fontSize: 56,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'KCAL EATEN',
                style: AppTypography.labelSmall.copyWith(
                  color: context.textMutedColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                borderRadius: 20,
                backgroundColor: context.surfaceColor.withOpacity(0.5),
                borderColor: context.glassBorderColor.withOpacity(0.3),
                child: Text(
                  remaining >= 0
                      ? '$remaining kcal left'
                      : '${remaining.abs()} over',
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        remaining >= 0
                            ? context.textPrimaryColor
                            : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color? color;
  final Gradient? gradient;
  final double strokeWidth;
  final bool hasGlow;

  _RingPainter({
    required this.progress,
    this.color,
    this.gradient,
    required this.strokeWidth,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = color ?? Colors.white;
    }

    if (hasGlow && progress > 0) {
      final glowPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth + 4
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      if (gradient != null) {
        glowPaint.shader = gradient!.createShader(rect);
        glowPaint.color = Colors.white.withOpacity(0.3); // Mix for glow
      } else {
        glowPaint.color = (color ?? Colors.white).withOpacity(0.3);
      }

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.gradient != gradient;
  }
}
