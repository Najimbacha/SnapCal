import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme_colors.dart';

/// A ruler that slides under a fixed pointer: drag it, flick it, and it
/// settles on the nearest step.
///
/// Used for height, weight and target weight. Every step it passes gives a
/// selection tick, the arrow and page keys move it, and screen readers see
/// an adjustable slider. It always lays out left to right: numbers on a scale
/// read that way in Arabic too.
class RulerPicker extends StatefulWidget {
  const RulerPicker({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.majorEvery,
    this.midEvery,
    this.pixelsPerStep = 8,
    this.axis = Axis.horizontal,
    required this.labelFor,
    required this.onChanged,
    required this.semanticLabel,
    required this.semanticValueFor,
    this.interactive = true,
  });

  final double value;
  final double min;
  final double max;

  /// The smallest change: 0.1 kg, 1 cm, 1 inch.
  final double step;

  /// Every [majorEvery] steps get a long, labelled tick; every [midEvery]
  /// a medium one.
  final int majorEvery;
  final int? midEvery;
  final double pixelsPerStep;
  final Axis axis;
  final String Function(double value) labelFor;
  final ValueChanged<double> onChanged;
  final String semanticLabel;
  final String Function(double value) semanticValueFor;

  /// False for a decorative ruler that only shows a value.
  final bool interactive;

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  final FocusNode _focus = FocusNode(debugLabel: 'RulerPicker');

  /// Where the pointer is, between steps while the ruler moves.
  late double _position;
  late double _lastEmitted;

  /// True from the moment the user touches the ruler until it has settled,
  /// so the value the parent echoes back mid-gesture doesn't yank it.
  bool _interacting = false;
  bool _flinging = false;

  bool get _vertical => widget.axis == Axis.vertical;
  double get _unitsPerPixel => widget.step / widget.pixelsPerStep;

  @override
  void initState() {
    super.initState();
    // Created here, not lazily: a ruler that was never touched would
    // otherwise create its ticker for the first time inside dispose().
    _motion = AnimationController.unbounded(vsync: this)
      ..addListener(_onMotion);
    _position = _snap(widget.value);
    _lastEmitted = _position;
  }

  @override
  void didUpdateWidget(RulerPicker old) {
    super.didUpdateWidget(old);
    final rangeChanged =
        old.min != widget.min ||
        old.max != widget.max ||
        old.step != widget.step;
    final moved = (widget.value - _snap(_position)).abs() > widget.step / 2;
    if (rangeChanged || (!_interacting && moved)) {
      _motion.stop();
      _interacting = false;
      _flinging = false;
      _position = _snap(widget.value);
      _lastEmitted = _position;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _focus.dispose();
    super.dispose();
  }

  double _clamp(double v) => v.clamp(widget.min, widget.max).toDouble();

  /// The nearest step, without the float noise that 0.1 * 723 carries.
  double _snap(double v) {
    final steps = (_clamp(v) / widget.step).round();
    return _clamp(double.parse((steps * widget.step).toStringAsFixed(6)));
  }

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _emit() {
    final value = _snap(_position);
    if (value == _lastEmitted) return;
    _lastEmitted = value;
    HapticFeedback.selectionClick();
    widget.onChanged(value);
  }

  void _onMotion() {
    final raw = _motion.value;
    final clamped = _clamp(raw);
    setState(() => _position = clamped);
    _emit();
    if (_flinging && clamped != raw) {
      _motion.stop();
      _settle();
    }
  }

  void _onDragStart(DragStartDetails _) {
    _motion.stop();
    _flinging = false;
    _interacting = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // Dragging the scale right or down brings lower values under a
    // horizontal pointer and higher ones under a vertical one.
    final pixels = _vertical ? details.delta.dy : -details.delta.dx;
    setState(() => _position = _clamp(_position + pixels * _unitsPerPixel));
    _emit();
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final pixelsPerSecond = _vertical ? velocity.dy : -velocity.dx;
    if (_reduceMotion || pixelsPerSecond.abs() < 80) {
      _settle();
      return;
    }
    _flinging = true;
    _motion.value = _position;
    _motion
        .animateWith(
          FrictionSimulation(
            0.02,
            _position,
            pixelsPerSecond * _unitsPerPixel,
            // Done once it drifts slower than a few steps a second; the snap
            // takes it the rest of the way instead of a long crawl.
            tolerance: Tolerance(velocity: widget.step * 4),
          ),
        )
        .then((_) {
          if (mounted && _flinging) _settle();
        });
  }

  void _settle() {
    _flinging = false;
    final target = _snap(_position);
    if (_reduceMotion || (target - _position).abs() < 1e-9) {
      setState(() => _position = target);
      _interacting = false;
      _emit();
      return;
    }
    _motion.value = _position;
    _motion
        .animateTo(
          target,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (!mounted) return;
          _position = target;
          _interacting = false;
          _emit();
        });
  }

  void _nudge(int steps) {
    _motion.stop();
    _flinging = false;
    _interacting = false;
    setState(() => _position = _snap(_position + steps * widget.step));
    _emit();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final steps = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.pageUp => 10,
      LogicalKeyboardKey.pageDown => -10,
      _ => 0,
    };
    if (steps == 0) return KeyEventResult.ignored;
    _nudge(steps);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final snapped = _snap(_position);
    final painter = _RulerPainter(
      position: _position,
      min: widget.min,
      max: widget.max,
      step: widget.step,
      pixelsPerStep: widget.pixelsPerStep,
      majorEvery: widget.majorEvery,
      midEvery: widget.midEvery,
      vertical: _vertical,
      labelFor: widget.labelFor,
      majorColor: context.textPrimaryColor,
      minorColor: context.textMutedColor.withValues(alpha: 0.75),
      pointerColor: context.primaryColor,
      // From the theme, so the labels are in the app's typeface rather
      // than the platform default a bare TextStyle falls back to.
      labelStyle: (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
          .copyWith(
            color: context.textPrimaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
      textScaler: MediaQuery.textScalerOf(context),
    );

    final fade = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback:
          (bounds) => LinearGradient(
            begin: _vertical ? Alignment.topCenter : Alignment.centerLeft,
            end: _vertical ? Alignment.bottomCenter : Alignment.centerRight,
            colors: const [
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
            ],
            stops: const [0, 0.16, 0.84, 1],
          ).createShader(bounds),
      child: CustomPaint(painter: painter, size: Size.infinite),
    );

    final ruler = Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.expand(child: fade),
    );

    if (!widget.interactive) return ExcludeSemantics(child: ruler);

    return Semantics(
      slider: true,
      focusable: true,
      label: widget.semanticLabel,
      value: widget.semanticValueFor(snapped),
      increasedValue: widget.semanticValueFor(_snap(snapped + widget.step)),
      decreasedValue: widget.semanticValueFor(_snap(snapped - widget.step)),
      onIncrease: () => _nudge(1),
      onDecrease: () => _nudge(-1),
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _focus.requestFocus(),
          onHorizontalDragStart: _vertical ? null : _onDragStart,
          onHorizontalDragUpdate: _vertical ? null : _onDragUpdate,
          onHorizontalDragEnd: _vertical ? null : _onDragEnd,
          onVerticalDragStart: _vertical ? _onDragStart : null,
          onVerticalDragUpdate: _vertical ? _onDragUpdate : null,
          onVerticalDragEnd: _vertical ? _onDragEnd : null,
          child: ruler,
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.position,
    required this.min,
    required this.max,
    required this.step,
    required this.pixelsPerStep,
    required this.majorEvery,
    required this.midEvery,
    required this.vertical,
    required this.labelFor,
    required this.majorColor,
    required this.minorColor,
    required this.pointerColor,
    required this.labelStyle,
    required this.textScaler,
  });

  final double position;
  final double min;
  final double max;
  final double step;
  final double pixelsPerStep;
  final int majorEvery;
  final int? midEvery;
  final bool vertical;
  final String Function(double value) labelFor;
  final Color majorColor;
  final Color minorColor;
  final Color pointerColor;
  final TextStyle labelStyle;
  final TextScaler textScaler;

  static const _labelBand = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final length = vertical ? size.height : size.width;
    final center = length / 2;
    final pixelsPerUnit = pixelsPerStep / step;
    final halfSpan = center / pixelsPerUnit + step;
    // Integer step indices, so "is this a major tick" is exact arithmetic.
    final first = ((position - halfSpan).clamp(min, max) / step).ceil();
    final last = ((position + halfSpan).clamp(min, max) / step).floor();

    final major =
        Paint()
          ..color = majorColor
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
    final minor =
        Paint()
          ..color = minorColor
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;

    final tickSpace = vertical ? 64.0 : size.height - _labelBand;

    for (var i = first; i <= last; i++) {
      final value = i * step;
      if (value < min - 1e-9 || value > max + 1e-9) continue;
      final isMajor = i % majorEvery == 0;
      final isMid = !isMajor && midEvery != null && i % midEvery! == 0;
      final offset = (value - position) * pixelsPerUnit;
      final p = vertical ? center - offset : center + offset;
      final tick = tickSpace * (isMajor ? 1 : (isMid ? 0.7 : 0.45));

      if (vertical) {
        canvas.drawLine(Offset(0, p), Offset(tick, p), isMajor ? major : minor);
      } else {
        canvas.drawLine(
          Offset(p, size.height),
          Offset(p, size.height - tick),
          isMajor ? major : minor,
        );
      }

      if (isMajor) {
        final text = TextPainter(
          text: TextSpan(text: labelFor(value), style: labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout();
        final at =
            vertical
                ? Offset(tickSpace + 12, p - text.height / 2)
                : Offset(p - text.width / 2, (_labelBand - text.height) / 2);
        text.paint(canvas, at);
        text.dispose();
      }
    }

    final pointer =
        Paint()
          ..color = pointerColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    if (vertical) {
      canvas.drawLine(
        Offset(0, center),
        Offset(size.width * 0.76, center),
        pointer,
      );
    } else {
      canvas.drawLine(
        Offset(center, _labelBand - 4),
        Offset(center, size.height),
        pointer,
      );
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.position != position ||
      old.min != min ||
      old.max != max ||
      old.step != step ||
      old.pixelsPerStep != pixelsPerStep ||
      old.majorEvery != majorEvery ||
      old.midEvery != midEvery ||
      old.vertical != vertical ||
      old.majorColor != majorColor ||
      old.minorColor != minorColor ||
      old.pointerColor != pointerColor ||
      old.labelStyle != labelStyle ||
      old.textScaler != textScaler;
}
