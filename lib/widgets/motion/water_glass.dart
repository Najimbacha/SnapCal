import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import 'visible_gate.dart';

/// A glass showing how much of today's water is drunk.
///
/// When the level rises a drop falls in first (with [showDrop]), then the
/// water climbs, overshooting a touch, and its surface sloshes and settles.
/// It is still between changes, so nothing animates while nobody is drinking.
class WaterGlass extends StatefulWidget {
  const WaterGlass({
    super.key,
    required this.level,
    required this.color,
    required this.outline,
    this.size = const Size(22, 32),
    this.showDrop = false,
    this.fillFromEmpty = false,
  });

  /// 0 for empty, 1 for full.
  final double level;
  final Color color;
  final Color outline;
  final Size size;
  final bool showDrop;

  /// Fills up from empty the first time it shows.
  final bool fillFromEmpty;

  @override
  State<WaterGlass> createState() => _WaterGlassState();
}

class _WaterGlassState extends State<WaterGlass>
    with SingleTickerProviderStateMixin, VisibleGate {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
    value: 1,
  );
  late double _from = widget.fillFromEmpty ? 0 : _clamped(widget.level);
  late double _to = _clamped(widget.level);
  bool _drop = false;

  static double _clamped(double v) => v.isFinite ? v.clamp(0.0, 1.0) : 0.0;

  @override
  void initState() {
    super.initState();
    if (_from != _to) {
      _controller.value = 0;
      runWhenVisible(_start);
    }
  }

  @override
  void didUpdateWidget(WaterGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _clamped(widget.level);
    if (next == _to) return;
    _from = _levelAt(_controller.value);
    _drop = widget.showDrop && next > _to;
    _to = next;
    _controller.value = 0;
    runWhenVisible(_start);
  }

  void _start() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  /// The drop takes the first fifth; the water rises after it lands.
  double _levelAt(double v) {
    final t = Interval(
      _drop ? .2 : 0,
      .62,
      curve: AppMotion.springCurve,
    ).transform(v);
    return _from + (_to - _from) * t;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${(_to * 100).round()}%',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final v = _controller.value;
            final slosh = Interval(_drop ? .2 : 0, 1).transform(v);
            return CustomPaint(
              size: widget.size,
              painter: _GlassPainter(
                level: _levelAt(v),
                // A wave that dies away as the water settles.
                amplitude: v >= 1 ? 0 : math.pow(1 - slosh, 2).toDouble(),
                phase: slosh * math.pi * 5,
                drop: _drop && v < .22 ? v / .22 : null,
                color: widget.color,
                outline: widget.outline,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  const _GlassPainter({
    required this.level,
    required this.amplitude,
    required this.phase,
    required this.drop,
    required this.color,
    required this.outline,
  });

  final double level, amplitude, phase;

  /// How far the falling drop has got, 0 to 1, or null for no drop.
  final double? drop;
  final Color color, outline;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = math.max(1.0, w / 22);
    // A tumbler, a little narrower at the foot.
    final glass =
        Path()
          ..moveTo(w * .06, h * .05)
          ..lineTo(w * .94, h * .05)
          ..lineTo(w * .8, h * .95)
          ..lineTo(w * .2, h * .95)
          ..close();
    final top = h * .1, bottom = h * .95 - stroke;
    final surface = bottom - (bottom - top) * level;
    final waveHeight = amplitude * h * .06;

    if (level > 0) {
      final water = Path()..moveTo(0, surface);
      for (var x = 0.0; x <= w; x += 1) {
        water.lineTo(
          x,
          surface + math.sin(x / w * math.pi * 2 + phase) * waveHeight,
        );
      }
      water
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas
        ..save()
        ..clipPath(glass);
      canvas.drawPath(water, Paint()..color = color.withValues(alpha: .88));
      // A lighter band just under the surface catches the light.
      canvas.drawLine(
        Offset(w * .2, surface + stroke * 1.6),
        Offset(w * .45, surface + stroke * 1.6),
        Paint()
          ..color = Colors.white.withValues(alpha: .35)
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    final d = drop;
    if (d != null) {
      final r = w * .09;
      final y = -h * .25 + (surface + h * .25) * Curves.easeIn.transform(d);
      final center = Offset(w / 2, y);
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - r * 1.8)
          ..quadraticBezierTo(
            center.dx + r * 1.1,
            center.dy - r * .2,
            center.dx,
            center.dy + r,
          )
          ..quadraticBezierTo(
            center.dx - r * 1.1,
            center.dy - r * .2,
            center.dx,
            center.dy - r * 1.8,
          ),
        Paint()..color = color.withValues(alpha: 1 - d * .3),
      );
    }

    canvas.drawPath(
      glass,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.level != level ||
      old.amplitude != amplitude ||
      old.phase != phase ||
      old.drop != drop ||
      old.color != color ||
      old.outline != outline;
}
