import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Animated food viewfinder guide overlay with corner brackets
class FoodFrameGuide extends StatefulWidget {
  const FoodFrameGuide({super.key});

  @override
  State<FoodFrameGuide> createState() => _FoodFrameGuideState();
}

class _FoodFrameGuideState extends State<FoodFrameGuide>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final guideSize = size.width * 0.7;

    return IgnorePointer(
      child: Stack(
        children: [
          // Dark vignette around the guide area
          Center(
            child: CustomPaint(
              size: size,
              painter: _VignettePainter(guideSize: guideSize),
            ),
          ),

          // Animated corner brackets
          Center(
            child: AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                final expansion = _breathAnimation.value;
                final currentSize = guideSize + expansion;
                return SizedBox(
                  width: currentSize,
                  height: currentSize,
                  child: CustomPaint(
                    painter: _CornerBracketPainter(
                      color: AppColors.primary,
                      strokeWidth: 3.0,
                      cornerLength: 28.0,
                      cornerRadius: 16.0,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a subtle vignette around the food guide area
class _VignettePainter extends CustomPainter {
  final double guideSize;

  _VignettePainter({required this.guideSize});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final guideRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: guideSize, height: guideSize),
      const Radius.circular(16),
    );

    final path =
        Path()
          ..addRect(rect)
          ..addRRect(guideRect);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(covariant _VignettePainter oldDelegate) =>
      oldDelegate.guideSize != guideSize;
}

/// Paints corner brackets for the viewfinder
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final l = cornerLength;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, l)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(l, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(w - l, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, l),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, h - l)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(l, h),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(w - l, h)
        ..lineTo(w - r, h)
        ..quadraticBezierTo(w, h, w, h - r)
        ..lineTo(w, h - l),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.cornerLength != cornerLength;
}
