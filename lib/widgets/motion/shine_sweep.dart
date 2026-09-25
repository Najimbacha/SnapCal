import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import 'visible_gate.dart';

/// A band of light that crosses its child once, after [delay]: for the one
/// thing on a screen worth a second look, like a Pro card or a main button.
class ShineSweep extends StatefulWidget {
  const ShineSweep({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.delay = Duration.zero,
    this.sweep = const Duration(milliseconds: 1100),
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Duration delay;
  final Duration sweep;

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin, VisibleGate {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.delay + widget.sweep,
    );
    runWhenVisible(() {
      if (!AppMotion.reduceMotion(context)) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.delay + widget.sweep;
    final start =
        total.inMicroseconds == 0
            ? 0.0
            : widget.delay.inMicroseconds / total.inMicroseconds;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = Interval(
                    start,
                    1,
                    curve: Curves.easeInOutCubic,
                  ).transform(_controller.value);
                  if (t <= 0 || t >= 1) return const SizedBox.shrink();
                  return FractionalTranslation(
                    translation: Offset(-1 + 2.4 * t, 0),
                    child: FractionallySizedBox(
                      widthFactor: .4,
                      alignment: Alignment.centerLeft,
                      child: Transform(
                        transform: Matrix4.skewX(-.3),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(
                                  alpha: dark ? .16 : .55,
                                ),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
