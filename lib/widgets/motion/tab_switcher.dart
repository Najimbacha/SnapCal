import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Holds the tab pages, keeping every one alive like an indexed stack, and
/// glides between them: the page being left fades out quickly while the new
/// one fades in drifting from the side it lies on. The camera tab only
/// fades, since it does not sit beside the others.
class TabSwitcher extends StatefulWidget {
  const TabSwitcher({
    super.key,
    required this.currentIndex,
    required this.children,
    this.fadeOnlyIndex,
  });

  final int currentIndex;
  final List<Widget> children;

  /// A page that arrives and leaves without drifting sideways.
  final int? fadeOnlyIndex;

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  late int _previous = widget.currentIndex;

  @override
  void didUpdateWidget(TabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == oldWidget.currentIndex) return;
    _previous = oldWidget.currentIndex;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final leaving = t < 1 && _previous != widget.currentIndex;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final forward = widget.currentIndex > _previous;
        final slides =
            widget.currentIndex != widget.fadeOnlyIndex &&
            _previous != widget.fadeOnlyIndex;
        final drift = (forward ? 1 : -1) * (rtl ? -1 : 1) * 28.0;
        final enter = Curves.easeOutCubic.transform(
          ((t - .12) / .88).clamp(0.0, 1.0),
        );
        final exit = Curves.easeIn.transform((t / .4).clamp(0.0, 1.0));

        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              _page(
                i,
                current: i == widget.currentIndex,
                leaving: leaving && i == _previous,
                enter: enter,
                exit: exit,
                drift: slides ? drift : 0,
              ),
          ],
        );
      },
    );
  }

  Widget _page(
    int i, {
    required bool current,
    required bool leaving,
    required double enter,
    required double exit,
    required double drift,
  }) {
    final visible = current || leaving;
    // The same wrapping at rest and in motion, so a page never loses its
    // state when a switch starts or ends.
    var opacity = 1.0, dx = 0.0;
    if (current && enter < 1) {
      opacity = enter;
      dx = drift * (1 - enter);
    } else if (leaving) {
      opacity = 1 - exit;
      dx = -drift * .4 * exit;
    }
    final child = Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: widget.children[i],
      ),
    );
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: current,
        child: IgnorePointer(ignoring: !current, child: child),
      ),
    );
  }
}
