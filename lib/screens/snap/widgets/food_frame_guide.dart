import 'package:flutter/material.dart';

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
    _breathAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
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
      child: Center(
        child: AnimatedBuilder(
          animation: _breathAnimation,
          builder: (context, child) {
            final expansion = _breathAnimation.value;
            return SizedBox(
              width: guideSize + expansion,
              height: guideSize + expansion,
              child: CustomPaint(
                painter: _CornerBracketPainter(
                  color: Colors.white.withValues(alpha: 0.4),
                  strokeWidth: 2.0,
                  cornerLength: 24.0,
                  cornerRadius: 14.0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final l = cornerLength;

    canvas.drawPath(
      Path()..moveTo(0, l)..lineTo(0, r)..quadraticBezierTo(0, 0, r, 0)..lineTo(l, 0),
      paint,
    );
    canvas.drawPath(
      Path()..moveTo(w - l, 0)..lineTo(w - r, 0)..quadraticBezierTo(w, 0, w, r)..lineTo(w, l),
      paint,
    );
    canvas.drawPath(
      Path()..moveTo(0, h - l)..lineTo(0, h - r)..quadraticBezierTo(0, h, r, h)..lineTo(l, h),
      paint,
    );
    canvas.drawPath(
      Path()..moveTo(w - l, h)..lineTo(w - r, h)..quadraticBezierTo(w, h, w, h - r)..lineTo(w, h - l),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}
