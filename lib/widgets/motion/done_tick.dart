import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// A small filled circle that pops in and draws a tick: the end of a job a
/// row was busy with, such as a restore or an export.
class DoneTick extends StatelessWidget {
  const DoneTick({super.key, required this.color, this.size = 22});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.maybeZero(context, const Duration(milliseconds: 560)),
      builder: (context, t, _) {
        // The circle springs in over the first half, the tick draws after.
        final pop = AppMotion.springCurve.transform((t / .55).clamp(0.0, 1.0));
        final draw = Curves.easeOutCubic.transform(
          ((t - .3) / .7).clamp(0.0, 1.0),
        );
        return Transform.scale(
          scale: pop,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: CustomPaint(painter: _TickPainter(draw)),
          ),
        );
      },
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path =
        Path()
          ..moveTo(size.width * .28, size.height * .52)
          ..lineTo(size.width * .44, size.height * .67)
          ..lineTo(size.width * .73, size.height * .36);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}
