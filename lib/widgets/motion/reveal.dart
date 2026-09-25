import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import 'visible_gate.dart';

/// Brings its child in once: fading up from a little below, after [delay].
///
/// For a screen that assembles itself in sequence. The delay is part of the
/// animation rather than a timer, so nothing is left pending if the screen
/// closes early.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.reveal,
    this.offset = const Offset(0, 16),
    this.scale = 1,
    this.curve = AppMotion.entranceCurve,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Where the child starts, in logical pixels from where it ends.
  final Offset offset;

  /// The child's starting scale; 1 for none.
  final double scale;
  final Curve curve;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal>
    with SingleTickerProviderStateMixin, VisibleGate {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );

  @override
  void initState() {
    super.initState();
    runWhenVisible(() {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.delay + widget.duration;
    final start =
        total.inMicroseconds == 0
            ? 0.0
            : widget.delay.inMicroseconds / total.inMicroseconds;
    final motion = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: widget.curve),
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = motion.value;
        return Opacity(
          opacity: fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: Transform.scale(
              scale: widget.scale + (1 - widget.scale) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
