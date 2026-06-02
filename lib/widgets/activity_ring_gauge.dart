import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ActivityRingGauge extends StatefulWidget {
  final double progress;
  final int steps;
  final String centerSubLabel;
  final double size;

  const ActivityRingGauge({
    super.key,
    required this.progress,
    required this.steps,
    required this.centerSubLabel,
    this.size = 220,
  });

  @override
  State<ActivityRingGauge> createState() => _ActivityRingGaugeState();
}

class _ActivityRingGaugeState extends State<ActivityRingGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _progressAnimation;
  Animation<double>? _stepsAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _initAnimations();
    _controller.forward();
  }

  void _initAnimations() {
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _stepsAnimation = Tween<double>(
      begin: 0,
      end: widget.steps.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant ActivityRingGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.steps != widget.steps) {
      final beginProgress = _progressAnimation?.value ?? oldWidget.progress;
      final beginSteps = _stepsAnimation?.value ?? oldWidget.steps.toDouble();

      _progressAnimation = Tween<double>(
        begin: beginProgress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _stepsAnimation = Tween<double>(
        begin: beginSteps,
        end: widget.steps.toDouble(),
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If animations are null for any reason (e.g. state issues during hot reload), fallback to final values
    final currentProgress = _progressAnimation?.value ?? widget.progress;
    final currentSteps = _stepsAnimation?.value.round() ?? widget.steps;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final animatedProgress = _progressAnimation?.value ?? currentProgress;
          final animatedSteps = _stepsAnimation?.value.round() ?? currentSteps;

          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: animatedProgress,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  gradient: AppColors.wellnessGlow,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$animatedSteps',
                    style: TextStyle(
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.centerSubLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: widget.size * 0.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Gradient gradient;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.08;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Full circle (360 degrees) starting from top
    const startAngle = -math.pi / 2;
    const sweepAngle = 2 * math.pi;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint =
        Paint()
          ..color = backgroundColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final fgPaint =
        Paint()
          ..shader = gradient.createShader(rect)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Draw background track
    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    // Draw progress track
    final progressSweep = sweepAngle * progress.clamp(0.0, 1.0);
    if (progressSweep > 0) {
      canvas.drawArc(rect, startAngle, progressSweep, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
