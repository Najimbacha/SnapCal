import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_motion.dart';

/// Lifts its child a little when it becomes [ready]: a Save button waking up
/// once there is something to save.
class LiftWhenReady extends StatefulWidget {
  const LiftWhenReady({super.key, required this.ready, required this.child});

  final bool ready;
  final Widget child;

  @override
  State<LiftWhenReady> createState() => _LiftWhenReadyState();
}

class _LiftWhenReadyState extends State<LiftWhenReady>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void didUpdateWidget(LiftWhenReady oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !oldWidget.ready && !AppMotion.reduceMotion(context)) {
      _lift.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _lift,
    child: widget.child,
    builder:
        (context, child) => Transform.translate(
          offset: Offset(0, -5 * math.sin(_lift.value * math.pi)),
          child: child,
        ),
  );
}
