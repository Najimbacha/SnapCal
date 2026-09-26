import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import 'visible_gate.dart';

/// A list row that opens a space for itself and slides in, with a brief
/// green wash, when [arrived] -- a meal just logged or brought back. Rows
/// that were already there simply show.
///
/// Set [leaving] to send it the other way: it slides out and the list closes
/// the gap, then [onLeft] is called.
class ArrivingItem extends StatefulWidget {
  const ArrivingItem({
    super.key,
    required this.arrived,
    required this.child,
    this.leaving = false,
    this.onLeft,
  });

  final bool arrived;
  final Widget child;
  final bool leaving;
  final VoidCallback? onLeft;

  @override
  State<ArrivingItem> createState() => _ArrivingItemState();
}

class _ArrivingItemState extends State<ArrivingItem>
    with TickerProviderStateMixin, VisibleGate {
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

  late final AnimationController _leave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );

  @override
  void didUpdateWidget(ArrivingItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving && !oldWidget.leaving) {
      if (AppMotion.reduceMotion(context)) {
        widget.onLeft?.call();
      } else {
        _leave.forward().whenComplete(() {
          if (mounted) widget.onLeft?.call();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _leave.dispose();
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
    final away = CurvedAnimation(
      parent: _leave,
      curve: const Interval(0, .45, curve: Curves.easeIn),
    );
    final close = CurvedAnimation(
      parent: _leave,
      curve: const Interval(.45, 1, curve: Curves.easeInOutCubic),
    );
    final side = Directionality.of(context) == TextDirection.rtl ? 1 : -1;
    final arriving = SizeTransition(
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
    return AnimatedBuilder(
      animation: _leave,
      child: arriving,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: ReverseAnimation(close),
          axisAlignment: -1,
          child: Opacity(
            opacity: 1 - away.value,
            child: Transform.translate(
              offset: Offset(side * 60 * away.value, 0),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
