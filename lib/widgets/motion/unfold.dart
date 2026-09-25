import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Opens its child downwards when [open] turns on and folds it away when it
/// turns off, pushing what is below it along rather than jumping.
///
/// The child is only built while it is showing, so anything inside it that
/// animates on arrival (a [Reveal]) plays each time it unfolds.
class Unfold extends StatefulWidget {
  const Unfold({super.key, required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  State<Unfold> createState() => _UnfoldState();
}

class _UnfoldState extends State<Unfold> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: widget.open ? 1 : 0,
  );

  @override
  void didUpdateWidget(Unfold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = widget.open ? 1 : 0;
    } else if (widget.open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.value == 0) return const SizedBox.shrink();
        return SizeTransition(
          sizeFactor: size,
          axisAlignment: -1,
          child: FadeTransition(opacity: size, child: widget.child),
        );
      },
    );
  }
}
