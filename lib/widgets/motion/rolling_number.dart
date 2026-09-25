import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../core/theme/app_motion.dart';
import 'visible_gate.dart';

/// A whole number whose digits roll to a new value like an odometer.
///
/// Each digit slides through the ones between old and new, left to right a
/// beat apart; separators stay put, and digits that appear or disappear fold
/// in and out. At rest it is a plain [Text], so it reads and finds the same
/// as any other number.
class RollingNumber extends StatefulWidget {
  const RollingNumber({
    super.key,
    required this.value,
    required this.style,
    this.from,
    this.format,
    this.delay = Duration.zero,
    this.duration = AppMotion.count,
  });

  final int value;
  final TextStyle style;

  /// Rolls from this on first show instead of appearing at [value].
  final int? from;

  /// Defaults to the locale's grouped decimal format.
  final String Function(int value)? format;
  final Duration delay;
  final Duration duration;

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber>
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
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.delay + widget.duration;
    if (widget.value == _to) return;
    // Mid-roll, carry on from where the digits are heading rather than
    // snapping back to where they started.
    _from = _to;
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(int v) =>
      widget.format?.call(v) ??
      NumberFormat.decimalPattern(
        Localizations.maybeLocaleOf(context)?.toString(),
      ).format(v);

  @override
  Widget build(BuildContext context) {
    final to = _format(_to);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
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
        final from = _format(_from);
        if (t >= 1 || from == to) return Text(to, style: widget.style);
        // Not started yet (still waiting to be seen, or in its delay).
        if (t <= 0) return Text(from, style: widget.style);
        return Semantics(
          label: to,
          child: ExcludeSemantics(child: _rolling(context, from, to, t)),
        );
      },
    );
  }

  Widget _rolling(BuildContext context, String from, String to, double t) {
    final painter = TextPainter(
      text: TextSpan(text: '0', style: widget.style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final digitWidth = painter.width;
    final height = painter.height;
    painter.dispose();

    // Aligned from the right, where the units are, so a number gaining a
    // digit grows on the left like an odometer.
    final n = math.max(from.length, to.length);
    final a = from.padLeft(n, '\u0000');
    final b = to.padLeft(n, '\u0000');
    final children = <Widget>[];
    for (var i = 0; i < n; i++) {
      final ca = a[i], cb = b[i];
      final local = Interval(
        math.min(i * 0.07, 0.4),
        1,
      ).transform(t.clamp(0.0, 1.0));
      if (ca == cb) {
        children.add(_char(cb, height));
        continue;
      }
      final da = _digit(ca), db = _digit(cb);
      if (da != null && db != null) {
        children.add(
          _DigitRoll(
            from: da.$1,
            to: db.$1,
            zero: db.$2,
            t: local,
            width: digitWidth,
            height: height,
            style: widget.style,
          ),
        );
        continue;
      }
      // A digit or separator arriving or leaving folds its width.
      if (ca != '\u0000') children.add(_folding(ca, 1 - local, height));
      if (cb != '\u0000') children.add(_folding(cb, local, height));
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _char(String c, double height) =>
      SizedBox(height: height, child: Text(c, style: widget.style));

  Widget _folding(String c, double f, double height) => ClipRect(
    child: Align(
      alignment: Alignment.centerRight,
      widthFactor: f.clamp(0.0, 1.0),
      child: Opacity(opacity: f.clamp(0.0, 1.0), child: _char(c, height)),
    ),
  );

  /// The digit's value and the code unit of its script's zero: Western,
  /// Arabic-Indic and Eastern Arabic-Indic digits all roll.
  static (int, int)? _digit(String c) {
    if (c.isEmpty || c == '\u0000') return null;
    final code = c.codeUnitAt(0);
    for (final zero in const [0x30, 0x660, 0x6F0]) {
      if (code >= zero && code <= zero + 9) return (code - zero, zero);
    }
    return null;
  }
}

class _DigitRoll extends StatelessWidget {
  const _DigitRoll({
    required this.from,
    required this.to,
    required this.zero,
    required this.t,
    required this.width,
    required this.height,
    required this.style,
  });

  final int from, to, zero;
  final double t, width, height;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final position = from + (to - from) * t;
    final lo = math.min(from, to), hi = math.max(from, to);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var k = lo; k <= hi; k++)
              if ((k - position).abs() < 1)
                Positioned(
                  left: 0,
                  right: 0,
                  top: (k - position) * height,
                  height: height,
                  child: Text(
                    String.fromCharCode(zero + k),
                    style: style,
                    textAlign: TextAlign.center,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
