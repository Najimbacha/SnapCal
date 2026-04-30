import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';

class LiquidCalorieCircle extends StatefulWidget {
  final int current;
  final int target;
  final Size size;

  const LiquidCalorieCircle({
    super.key,
    required this.current,
    required this.target,
    this.size = const Size(160, 160),
  });

  @override
  State<LiquidCalorieCircle> createState() => _LiquidCalorieCircleState();
}

class _LiquidCalorieCircleState extends State<LiquidCalorieCircle>
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
    final double percentage = math.min(1.0, widget.current / widget.target);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuccess = widget.current >= widget.target && widget.target > 0;

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Ring with Glow if Success
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isSuccess ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ] : [],
              border: Border.all(
                color: isSuccess 
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 8,
              ),
            ),
          ),
          
          // Liquid Container (Clip)
          ClipPath(
            clipper: _CircleClipper(),
            child: AnimatedBuilder(
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
                  size: widget.size,
                  painter: _WavePainter(
                    animationValue: _waveController.value,
                    percentage: percentage,
                    mainColor: isSuccess ? AppColors.primary : AppColors.primary,
                    isDark: isDark,
                    isSuccess: isSuccess,
                  ),
                );
              },
            ),
          ),

          // Text Overlay
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isSuccess ? 'GOAL' : '${widget.target - widget.current}',
                style: AppTypography.heading1.copyWith(
                  fontSize: isSuccess ? 32 : 52, // Massive, cinematic size
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -2.0,
                  color: isDark ? Colors.white : Colors.black,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (isSuccess ? 'COMPLETED' : 'kcal left').toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                  letterSpacing: 2.0, // High-end dashboard spacing
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final double percentage;
  final Color mainColor;
  final bool isDark;
  final bool isSuccess;

  _WavePainter({
    required this.animationValue,
    required this.percentage,
    required this.mainColor,
    required this.isDark,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double height = size.height;

    // The water level rises from bottom (height) to top (0)
    final double fillLevel = height - (percentage * height);

    if (isSuccess) {
      _drawWave(canvas, size, fillLevel, 1.0, 15, mainColor.withValues(alpha: 0.4), 0.0);
      _drawWave(canvas, size, fillLevel, 0.7, 20, mainColor.withValues(alpha: 0.6), math.pi / 2);
      _drawWave(canvas, size, fillLevel, 1.4, 12, mainColor, math.pi);
    } else {
      _drawWave(canvas, size, fillLevel, 1.0, 10, mainColor.withValues(alpha: 0.3), 0.0);
      _drawWave(canvas, size, fillLevel, 0.8, 15, mainColor.withValues(alpha: 0.5), math.pi / 2);
      _drawWave(canvas, size, fillLevel, 1.2, 8, mainColor, math.pi);
    }
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double fillLevel,
    double waveSpeed,
    double waveAmplitude,
    Color color,
    double phaseShift,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, fillLevel);

    for (double i = 0; i <= size.width; i++) {
      final double waveHeight = math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi * waveSpeed) + phaseShift) * waveAmplitude;
      path.lineTo(i, fillLevel + waveHeight);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => 
    oldDelegate.animationValue != animationValue || 
    oldDelegate.percentage != percentage;
}
