import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/theme_colors.dart';
import 'motion/visible_gate.dart';
import 'wazn_icons.dart';

/// The little picture on an empty page: a soft card whose outline draws
/// itself, the page's icon popping in the middle, a plus when there is
/// something to add, and a slow float once it is all in place.
class EmptyStateArt extends StatefulWidget {
  const EmptyStateArt({super.key, required this.icon, this.showPlus = false});

  final IconData icon;
  final bool showPlus;

  @override
  State<EmptyStateArt> createState() => _EmptyStateArtState();
}

class _EmptyStateArtState extends State<EmptyStateArt>
    with TickerProviderStateMixin, VisibleGate {
  late final AnimationController _draw;
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    runWhenVisible(() {
      if (AppMotion.reduceMotion(context)) {
        _draw.value = 1;
        return;
      }
      _draw.forward().whenComplete(() {
        if (mounted) _float.repeat();
      });
    });
  }

  @override
  void dispose() {
    _draw.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final ink = dark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
    final soft = AppColors.primary.withValues(alpha: dark ? 0.16 : 0.12);

    return SizedBox(
      width: 150,
      height: 130,
      child: AnimatedBuilder(
        animation: Listenable.merge([_draw, _float]),
        builder: (context, _) {
          final t = _draw.value;
          double part(double from, double to, [Curve curve = Curves.linear]) =>
              curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));
          final outline = part(0, .6, Curves.easeInOut);
          final fill = part(.4, .75);
          final iconPop = part(.45, .8, Curves.easeOutBack);
          final plusPop = part(.7, 1, AppMotion.springCurve);
          final bob = math.sin(_float.value * math.pi * 2);

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // The shadow narrows as the card lifts.
              Positioned(
                bottom: 6,
                child: Transform.scale(
                  scaleX: 1 - .07 * (bob + 1) / 2,
                  child: Opacity(
                    opacity: fill,
                    child: Container(
                      width: 92,
                      height: 12,
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(46, 6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, 18 - 3 * (bob + 1)),
                child: SizedBox(
                  width: 106,
                  height: 84,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CardPainter(
                            outline: outline,
                            fill: fill,
                            ink: ink,
                            soft: soft,
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: iconPop,
                        child: Icon(widget.icon, size: 38, color: ink),
                      ),
                      if (widget.showPlus)
                        Positioned(
                          top: -12,
                          right: -12,
                          child: Transform.rotate(
                            angle: -math.pi / 2 * (1 - plusPop),
                            child: Transform.scale(
                              scale: plusPop,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: ink,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  WaznIcons.plus,
                                  size: 20,
                                  color:
                                      dark
                                          ? const Color(0xFF0B110E)
                                          : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardPainter extends CustomPainter {
  const _CardPainter({
    required this.outline,
    required this.fill,
    required this.ink,
    required this.soft,
  });

  final double outline;
  final double fill;
  final Color ink;
  final Color soft;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    if (fill > 0) {
      canvas.drawRRect(
        rrect,
        Paint()..color = soft.withValues(alpha: soft.a * fill),
      );
    }
    if (outline <= 0) return;
    final metric = (Path()..addRRect(rrect)).computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * outline),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CardPainter old) =>
      old.outline != outline ||
      old.fill != fill ||
      old.ink != ink ||
      old.soft != soft;
}
