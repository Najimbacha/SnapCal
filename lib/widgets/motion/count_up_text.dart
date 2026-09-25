import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../core/theme/app_motion.dart';
import 'visible_gate.dart';

/// A whole number that counts to each new value instead of jumping.
///
/// For the smaller figures around a [RollingNumber]: grams, meal counts,
/// millilitres. With [from] set it also counts up the first time it shows.
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.from,
    this.format,
    this.delay = Duration.zero,
    this.duration = AppMotion.count,
    this.textAlign,
    this.maxLines,
  });

  final int value;
  final TextStyle? style;
  final int? from;

  /// Defaults to the locale's grouped decimal format.
  final String Function(int value)? format;
  final Duration delay;
  final Duration duration;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin, VisibleGate {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
    value: 1,
  );
  late int _from = widget.from ?? widget.value;
  late int _to = widget.value;

  @override
  void initState() {
    super.initState();
    if (_from != _to) {
      _controller.value = 0;
      runWhenVisible(_start);
    }
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.delay + widget.duration;
    if (widget.value == _to) return;
    _from = _current.round();
    _to = widget.value;
    _controller.value = 0;
    runWhenVisible(_start);
  }

  void _start() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  double get _current {
    final total = widget.delay + widget.duration;
    final start =
        total.inMicroseconds == 0
            ? 0.0
            : widget.delay.inMicroseconds / total.inMicroseconds;
    final t = Interval(
      start,
      1,
      curve: Curves.easeOutCubic,
    ).transform(_controller.value);
    return _from + (_to - _from) * t;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format =
        widget.format ??
        NumberFormat.decimalPattern(
          Localizations.maybeLocaleOf(context)?.toString(),
        ).format;
    return AnimatedBuilder(
      animation: _controller,
      builder:
          (context, _) => Text(
            format(_current.round()),
            style: widget.style,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
          ),
    );
  }
}
