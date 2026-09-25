import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import 'visible_gate.dart';

/// "+190" or "−610" floating up and away when [value] changes, so a total
/// that moved says by how much. Green for up, red for down; nothing at rest.
class DeltaBubble extends StatefulWidget {
  const DeltaBubble({
    super.key,
    required this.value,
    this.suffix = '',
    this.announce = true,
  });

  final int value;

  /// False for a change that is not an add or a removal, like switching to
  /// another day: the figure moves without a bubble.
  final bool announce;

  /// Appended to the figure, e.g. ' kcal'.
  final String suffix;

  @override
  State<DeltaBubble> createState() => _DeltaBubbleState();
}

class _DeltaBubbleState extends State<DeltaBubble>
    with SingleTickerProviderStateMixin, VisibleGate {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    value: 1,
  );
  int _delta = 0;

  @override
  void didUpdateWidget(DeltaBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == oldWidget.value || !widget.announce) return;
    _delta = widget.value - oldWidget.value;
    _controller.value = 0;
    runWhenVisible(() {
      if (AppMotion.reduceMotion(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
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
    final up = _delta > 0;
    final color = up ? AppColors.primary : AppColors.error;
    final number = NumberFormat.decimalPattern(
      Localizations.maybeLocaleOf(context)?.toString(),
    ).format(_delta.abs());
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final v = _controller.value;
            if (v <= 0 || v >= 1) return const SizedBox.shrink();
            final opacity =
                v < .15 ? v / .15 : (v > .7 ? 1 - (v - .7) / .3 : 1.0);
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 6 - 22 * Curves.easeOutCubic.transform(v)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${up ? '+' : '−'}$number${widget.suffix}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
