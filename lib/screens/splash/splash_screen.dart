import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Shown while the app starts.
///
/// The app icon builds itself: the scanning corners draw in, the plate pops,
/// the green ring sweeps round it and a sparkle lands, then the name rises a
/// letter at a time. It is short on purpose -- starting never waits for it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFF0B110E);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _between(double begin, double end, [Curve curve = Curves.linear]) =>
      curve.transform(
        ((_controller.value - begin) / (end - begin)).clamp(0.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            const name = 'Wazn';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  key: const ValueKey('splash-mark'),
                  size: const Size.square(132),
                  painter: _MarkPainter(
                    corners: _between(0, .35, Curves.easeInOutCubic),
                    plate: _between(.18, .45, const Cubic(.34, 1.45, .55, 1)),
                    ring: _between(.3, .72, Curves.easeInOutCubic),
                    sparkle: _between(.62, .88, const Cubic(.34, 1.6, .55, 1)),
                  ),
                ),
                const SizedBox(height: 22),
                Semantics(
                  label: name,
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < name.length; i++)
                          Builder(
                            builder: (context) {
                              final t = _between(
                                .5 + i * .05,
                                .78 + i * .05,
                                Curves.easeOutCubic,
                              );
                              return Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset(0, 14 * (1 - t)),
                                  child: Text(
                                    name[i],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: _between(.72, 1),
                  child: Text(
                    l10n?.splash_calorie_tracker ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The app icon drawn in stages, each 0 to 1.
class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.corners,
    required this.plate,
    required this.ring,
    required this.sparkle,
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
  bool shouldRepaint(_MarkPainter old) =>
      old.corners != corners ||
      old.plate != plate ||
      old.ring != ring ||
      old.sparkle != sparkle;
}
