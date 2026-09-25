import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/body_metric.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/motion/reveal.dart';
import '../../../widgets/motion/rolling_number.dart';
import '../../../widgets/motion/visible_gate.dart';
import '../../../widgets/wazn_icons.dart';

/// The weight line on the Progress screen.
///
/// It draws itself in from the left on first sight, each weigh-in popping
/// on as the line reaches it, while the latest weight rolls up. A finger
/// slid along it shows each weigh-in's date and weight; a new weigh-in
/// makes the line stretch out to reach its point.
class WeightTrendChart extends StatefulWidget {
  /// Newest first, as the metrics provider keeps them.
  final List<BodyMetric> metrics;
  final double? targetWeight;

  const WeightTrendChart({super.key, required this.metrics, this.targetWeight});

  @override
  State<WeightTrendChart> createState() => _WeightTrendChartState();
}

class _WeightTrendChartState extends State<WeightTrendChart>
    with TickerProviderStateMixin, VisibleGate {
  late final AnimationController _draw;
  late final AnimationController _morph;

  /// Points as fractions of the plot, oldest on the left.
  List<Offset> _from = const [];
  List<Offset> _to = const [];

  /// The weigh-in under the finger, and the last one shown so the bubble
  /// can fade out still saying something.
  int? _selected;
  int _shown = 0;

  List<BodyMetric> get _oldestFirst => widget.metrics.reversed.toList();

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _morph = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 1,
    );
    _to = _layout(_oldestFirst);
    _from = _to;
    runWhenVisible(() {
      if (AppMotion.reduceMotion(context)) {
        _draw.value = 1;
      } else {
        _draw.forward();
      }
    });
  }

  @override
  void didUpdateWidget(WeightTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _layout(_oldestFirst);
    if (_same(next, _to)) return;
    // Start from wherever the line is now; a new point grows out of the
    // last one.
    final now = _current;
    _from = [
      for (var i = 0; i < next.length; i++)
        i < now.length ? now[i] : (now.isEmpty ? next[i] : now.last),
    ];
    _to = next;
    _selected = null;
    if (AppMotion.reduceMotion(context)) {
      _morph.value = 1;
    } else {
      _morph.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _morph.dispose();
    super.dispose();
  }

  static bool _same(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).distanceSquared > 1e-9) return false;
    }
    return true;
  }

  List<Offset> get _current {
    final t = Curves.easeOutBack.transform(_morph.value);
    return [
      for (var i = 0; i < _to.length; i++)
        Offset(
          lerpDouble(_from[i].dx, _to[i].dx, t)!,
          lerpDouble(_from[i].dy, _to[i].dy, t)!,
        ),
    ];
  }

  static (double, double) _range(List<double> weights) {
    final lo = weights.reduce(math.min), hi = weights.reduce(math.max);
    final pad = (hi - lo) * 0.2;
    final minY = (lo - pad).floorToDouble();
    var maxY = (hi + pad).ceilToDouble();
    if (maxY == minY) maxY = minY + 1;
    return (minY, maxY);
  }

  static List<Offset> _layout(List<BodyMetric> oldestFirst) {
    if (oldestFirst.isEmpty) return const [];
    final weights = [for (final m in oldestFirst) m.weight];
    final (minY, maxY) = _range(weights);
    final n = weights.length;
    return [
      for (var i = 0; i < n; i++)
        Offset(
          n == 1 ? 0.5 : i / (n - 1),
          1 - (weights[i] - minY) / (maxY - minY),
        ),
    ];
  }

  void _pick(Offset local, Size size) {
    if (_to.isEmpty || size.width <= 0) return;
    final x = (local.dx / size.width).clamp(0.0, 1.0);
    var best = 0;
    for (var i = 1; i < _to.length; i++) {
      if ((_to[i].dx - x).abs() < (_to[best].dx - x).abs()) best = i;
    }
    if (best != _selected) {
      HapticFeedback.selectionClick();
      setState(() {
        _selected = best;
        _shown = best;
      });
    }
  }

  void _release() {
    if (_selected != null) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.metrics.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final days = DateFormat.MMMd(locale);
    final oldestFirst = _oldestFirst;
    final first = oldestFirst.first, last = oldestFirst.last;
    final change = last.weight - first.weight;
    final changeText =
        '${change <= 0 ? '−' : '+'}${change.abs().toStringAsFixed(1)} kg';
    final weights = [for (final m in oldestFirst) m.weight];
    final (_, maxY) = _range(weights);

    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.progress_weight_trend,
                      style: AppTypography.labelLarge.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (oldestFirst.length > 1) ...[
                      const SizedBox(height: 6),
                      // How far the line has come, arriving once it is drawn.
                      Reveal(
                        key: const ValueKey('weight-change'),
                        delay: const Duration(milliseconds: 1300),
                        offset: const Offset(12, 0),
                        scale: .9,
                        curve: AppMotion.springCurve,
                        child: _ChangeChip(
                          text: l10n.progress_change_since(
                            changeText,
                            days.format(first.date),
                          ),
                          down: change <= 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              RollingNumber(
                value: (last.weight * 10).round(),
                from: (first.weight * 10).round(),
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 1300),
                format: (v) => '${(v / 10).toStringAsFixed(1)} kg',
                style: AppTypography.titleLarge.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _pick(d.localPosition, size),
                  onTapUp: (_) => _release(),
                  onPanDown: (d) => _pick(d.localPosition, size),
                  onPanUpdate: (d) => _pick(d.localPosition, size),
                  onPanEnd: (_) => _release(),
                  onPanCancel: _release,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_draw, _morph]),
                    builder: (context, _) {
                      final points = _current;
                      final show = _shown.clamp(0, points.length - 1);
                      final at =
                          points.isEmpty
                              ? Offset.zero
                              : Offset(
                                points[show].dx * size.width,
                                points[show].dy * size.height,
                              );
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              key: const ValueKey('weight-trend-paint'),
                              painter: _ChartPainter(
                                points: points,
                                draw: _draw.value,
                                selected: _selected,
                                color: colorScheme.primary,
                                surface: colorScheme.surface,
                                labelColor: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                                topLabel: '${maxY.toStringAsFixed(0)} kg',
                                baseStyle:
                                    Theme.of(context).textTheme.bodySmall ??
                                    const TextStyle(),
                              ),
                            ),
                          ),
                          if (points.isNotEmpty)
                            Positioned(
                              left: (at.dx - 50).clamp(
                                -8.0,
                                math.max(-8.0, size.width - 92),
                              ),
                              top: at.dy - 52,
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  opacity: _selected == null ? 0 : 1,
                                  duration: AppMotion.maybeZero(
                                    context,
                                    const Duration(milliseconds: 180),
                                  ),
                                  child: _Bubble(
                                    key: const ValueKey('weight-bubble'),
                                    weight:
                                        '${oldestFirst[show.clamp(0, oldestFirst.length - 1)].weight.toStringAsFixed(1)} kg',
                                    date: days.format(
                                      oldestFirst[show.clamp(
                                            0,
                                            oldestFirst.length - 1,
                                          )]
                                          .date,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DateLabel(days.format(first.date)),
              _DateLabel(days.format(last.date)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({required this.text, required this.down});

  final String text;
  final bool down;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            down ? WaznIcons.trendDown : WaznIcons.trend,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.weight, required this.date});

  final String weight;
  final String date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            weight,
            style: AppTypography.labelLarge.copyWith(
              color: scheme.onInverseSurface,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            date,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onInverseSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final String text;
  const _DateLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.points,
    required this.draw,
    required this.selected,
    required this.color,
    required this.surface,
    required this.labelColor,
    required this.topLabel,
    required this.baseStyle,
  });

  /// Fractions of the plot, oldest first.
  final List<Offset> points;

  /// How far along the line is drawn, 0 to 1.
  final double draw;
  final int? selected;
  final Color color;
  final Color surface;
  final Color labelColor;
  final String topLabel;
  final TextStyle baseStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width, height = size.height;
    final gridPaint =
        Paint()
          ..color = labelColor.withValues(alpha: 0.2)
          ..strokeWidth = 1;
    canvas.drawLine(Offset(0, height), Offset(width, height), gridPaint);
    canvas.drawLine(Offset.zero, Offset(width, 0), gridPaint);
    final label = TextPainter(
      text: TextSpan(
        text: topLabel,
        style: baseStyle.copyWith(color: labelColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(width - label.width, -label.height - 2));
    label.dispose();

    if (points.isEmpty) return;
    final at = [for (final p in points) Offset(p.dx * width, p.dy * height)];
    final eased = Curves.easeInOutCubic.transform(draw.clamp(0.0, 1.0));

    final path = Path()..moveTo(at.first.dx, at.first.dy);
    for (var i = 1; i < at.length; i++) {
      final a = at[i - 1], b = at[i];
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final fill =
        Path.from(path)
          ..lineTo(at.last.dx, height)
          ..lineTo(at.first.dx, height)
          ..close();

    // Everything to the right of the pen is not drawn yet.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-8, -8, width * eased + 8, height + 8));
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, width, height)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    final sel = selected;
    if (sel != null && sel < at.length) {
      final x = at[sel].dx;
      final dash =
          Paint()
            ..color = labelColor
            ..strokeWidth = 1;
      for (var y = 0.0; y < height; y += 6) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 3, height)), dash);
      }
    }

    // Each weigh-in pops on as the pen passes it, a touch past full size.
    for (var i = 0; i < at.length; i++) {
      final reach = points[i].dx * 0.85;
      final t = ((eased - reach) / 0.15).clamp(0.0, 1.0);
      if (t <= 0) continue;
      var scale = AppMotion.springCurve.transform(t);
      if (i == sel) scale *= 1.6;
      final last = i == at.length - 1;
      canvas.drawCircle(
        at[i],
        (last ? 6 : 5) * scale,
        Paint()..color = surface,
      );
      canvas.drawCircle(
        at[i],
        (last ? 4.5 : 3) * scale,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.points != points ||
      old.draw != draw ||
      old.selected != selected ||
      old.color != color ||
      old.surface != surface ||
      old.labelColor != labelColor ||
      old.topLabel != topLabel;
}
