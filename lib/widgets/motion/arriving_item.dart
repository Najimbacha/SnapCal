import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import 'visible_gate.dart';

/// A list row that opens a space for itself and slides in, with a brief
/// green wash, when [arrived] -- a meal just logged or brought back. Rows
/// that were already there simply show.
class ArrivingItem extends StatefulWidget {
  const ArrivingItem({super.key, required this.arrived, required this.child});

  final bool arrived;
  final Widget child;

  @override
  State<ArrivingItem> createState() => _ArrivingItemState();
}

class _ArrivingItemState extends State<ArrivingItem>
    with SingleTickerProviderStateMixin, VisibleGate {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: widget.arrived ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.arrived) {
      runWhenVisible(() {
        if (AppMotion.reduceMotion(context)) {
          _controller.value = 1;
        } else {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .32, curve: Curves.easeOutCubic),
    );
    final slide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.12, .5, curve: AppMotion.springCurve),
    );
    final wash = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.35, 1, curve: Curves.easeIn),
    );
    return SizeTransition(
      sizeFactor: open,
      axisAlignment: -1,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final washAlpha =
              _controller.value >= 1 ? 0.0 : (1 - wash.value) * .10;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: washAlpha),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Opacity(
              opacity: slide.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -12 * (1 - slide.value)),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
