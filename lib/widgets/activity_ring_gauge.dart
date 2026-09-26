import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import 'motion/celebration.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _controller;

  /// The tip's pop once the ring lands, and the ring's swell when the goal
  /// is reached.
  late final AnimationController _pop;
  bool _reached = false;
  Animation<double>? _progressAnimation;
  Animation<double>? _stepsAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _controller.addStatusListener(_landed);
    _initAnimations();
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context) && _controller.isAnimating) {
      _controller.value = 1;
    }
  }

  void _landed(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (AppMotion.reduceMotion(context)) return;
    _pop.forward(from: 0);
    if (!_reached) return;
    _reached = false;
    // Reaching the goal: a buzz and a burst from the top of the ring, where
    // the ring closes.
    HapticFeedback.mediumImpact();
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      burstConfetti(
        context,
        box.localToGlobal(Offset(box.size.width / 2, box.size.width * .04)),
      );
    }
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
      _reached = beginProgress < 1 && widget.progress >= 1;

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
      if (AppMotion.reduceMotion(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pop.dispose();
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
        animation: Listenable.merge([_controller, _pop]),
        builder: (context, child) {
          final animatedProgress = _progressAnimation?.value ?? currentProgress;
          final animatedSteps = _stepsAnimation?.value.round() ?? currentSteps;
          final pop = math.sin(_pop.value * math.pi);
          final full = animatedProgress >= 1;

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: full ? 1 + .05 * pop : 1,
                child: CustomPaint(
                  key: const ValueKey('activity-ring'),
                  size: Size(widget.size, widget.size),
                  painter: _RingPainter(
                    progress: animatedProgress,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    gradient: AppColors.wellnessGlow,
                    // A glowing tip leads the ring round, and pops as it
                    // lands.
                    tipGlow: _controller.isAnimating ? .35 : .18 + .2 * pop,
                    tipScale: 1 + .6 * pop,
                  ),
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
  final double tipGlow;
  final double tipScale;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.gradient,
    this.tipGlow = 0,
    this.tipScale = 1,
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

    if (progress > .01) {
      final angle = startAngle + progressSweep;
      final tip = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        tip,
        strokeWidth * .9,
        Paint()..color = const Color(0xFFB8E23C).withValues(alpha: tipGlow),
      );
      canvas.drawCircle(
        tip,
        strokeWidth * .28 * tipScale,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tipGlow != tipGlow ||
        oldDelegate.tipScale != tipScale;
  }
}
