import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Wazn icon, drawn rather than loaded: the scan corners, the ring and
/// the plate, with its sparkle. The loading screen builds it in stages; the
/// purchase screen shows it whole.
class WaznMark extends StatelessWidget {
  const WaznMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const WaznMarkPainter());
}

/// The app icon drawn in stages, each 0 to 1.
class WaznMarkPainter extends CustomPainter {
  const WaznMarkPainter({
    this.corners = 1,
    this.plate = 1,
    this.ring = 1,
    this.sparkle = 1,
  });

  final double corners;
  final double plate;
  final double ring;
  final double sparkle;

  static const _green = Color(0xFF5EDB8C);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 150;
    canvas.scale(s);
    const centre = Offset(75, 75);

    if (corners > 0) {
      final paint =
          Paint()
            ..color = _green
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round;
      // Each corner slides in from the middle as it draws.
      final pull = (1 - corners) * 22;
      for (final (dx, dy) in const [
        (-1.0, -1.0),
        (1.0, -1.0),
        (1.0, 1.0),
        (-1.0, 1.0),
      ]) {
        final corner = Offset(75 + dx * (57 - pull), 75 + dy * (57 - pull));
        final path =
            Path()
              ..moveTo(corner.dx, corner.dy - dy * 30)
              ..lineTo(corner.dx, corner.dy - dy * 16)
              ..arcToPoint(
                Offset(corner.dx - dx * 16, corner.dy),
                radius: const Radius.circular(16),
                clockwise: dx * dy < 0,
              )
              ..lineTo(corner.dx - dx * 30, corner.dy);
        final metric = path.computeMetrics().first;
        canvas.drawPath(metric.extractPath(0, metric.length * corners), paint);
      }
    }

    if (ring > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: 36),
        -math.pi / 2,
        2 * math.pi * ring,
        false,
        Paint()
          ..shader = const SweepGradient(
            colors: [
              Color(0xFF14B8A6),
              Color(0xFF34D399),
              Color(0xFFB8E23C),
              Color(0xFF14B8A6),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: 36))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }

    if (plate > 0) {
      canvas.drawCircle(
        centre,
        29 * plate,
        Paint()..color = const Color(0xFF1A2420),
      );
      canvas.drawCircle(centre, 23 * plate, Paint()..color = Colors.white);
      canvas.drawCircle(
        centre,
        16 * plate,
        Paint()..color = const Color(0xFFEDEDEA),
      );
    }

    if (sparkle > 0) {
      canvas.save();
      canvas.translate(108, 50);
      canvas.rotate((1 - sparkle) * -math.pi / 2);
      canvas.scale(sparkle);
      final star =
          Path()
            ..moveTo(0, -8)
            ..lineTo(2.4, -2.4)
            ..lineTo(8, 0)
            ..lineTo(2.4, 2.4)
            ..lineTo(0, 8)
            ..lineTo(-2.4, 2.4)
            ..lineTo(-8, 0)
            ..lineTo(-2.4, -2.4)
            ..close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFB8E23C));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(WaznMarkPainter old) =>
      old.corners != corners ||
      old.plate != plate ||
      old.ring != ring ||
      old.sparkle != sparkle;
}
