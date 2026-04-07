import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CalorieRing extends StatelessWidget {
  final int consumed;
  final int goal;
  final double size;

  const CalorieRing({
    super.key,
    required this.consumed,
    required this.goal,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = goal - consumed;
    final accent = remaining < 0 ? AppColors.error : Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              activeColor: accent,
              secondaryColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${consumed.clamp(0, 99999)}',
                style: AppTypography.displayLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'of $goal kcal',
                style: AppTypography.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: ShapeDecoration(
                  color: remaining < 0 
                    ? Theme.of(context).colorScheme.errorContainer 
                    : Theme.of(context).colorScheme.secondaryContainer,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  remaining < 0 
                      ? '${remaining.abs()} over' 
                      : '${remaining.abs()} left',
                  style: AppTypography.labelLarge.copyWith(
                    color: remaining < 0 
                      ? Theme.of(context).colorScheme.onErrorContainer 
                      : Theme.of(context).colorScheme.onSecondaryContainer,
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
  final Color trackColor;
  final Color activeColor;
  final Color secondaryColor;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [secondaryColor, activeColor],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, active);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor;
  }
}
