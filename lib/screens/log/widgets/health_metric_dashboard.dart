import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_typography.dart';
import '../../../widgets/ui_blocks.dart';
import '../models/log_metric_models.dart';
import '../../../data/services/premium_conversion_service.dart';
import '../../../providers/settings_provider.dart';

enum HealthMetricChartStyle { bars, line }

Color _metricAccentFor(BuildContext context, LogMetricType type) {
  switch (type) {
    case LogMetricType.calories:
      return Theme.of(context).colorScheme.primary;
    case LogMetricType.energy:
      return AppColors.warning;
    case LogMetricType.steps:
      return AppColors.violet;
    case LogMetricType.water:
      return AppColors.sky;
    case LogMetricType.protein:
      return AppColors.protein;
    case LogMetricType.carbs:
      return AppColors.carbs;
    case LogMetricType.fat:
      return AppColors.fat;
  }
}

class HealthMetricCardData {
  final LogMetricType type;
  final String title;
  final String value;
  final String unit;
  final String status;
  final List<int> values;
  final int goal;
  final HealthMetricChartStyle chartStyle;
  final IconData icon;

  const HealthMetricCardData({
    required this.type,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.values,
    required this.goal,
    required this.chartStyle,
    required this.icon,
  });
}

class HealthMetricDashboard extends StatelessWidget {
  final String title;
  final String actionLabel;
  final List<HealthMetricCardData> cards;
  final ValueChanged<LogMetricType> onMetricTap;
  final VoidCallback? onCustomize;

  const HealthMetricDashboard({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.cards,
    required this.onMetricTap,
    this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LogSectionHeader(
          title: title,
          actionLabel: actionLabel,
          onAction: onCustomize,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final half = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < cards.length; i++)
                  SizedBox(
                    // Two per row, except a lone trailing tile, which takes
                    // the full width rather than sitting half-empty beside
                    // nothing. Free tiers land on an odd count often.
                    width:
                        (cards.length.isOdd && i == cards.length - 1)
                            ? constraints.maxWidth
                            : half,
                    child: HealthMetricCard(
                      key: ValueKey(cards[i].type.id),
                      data: cards[i],
                      onTap: () => onMetricTap(cards[i].type),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

/// The one section label used across the Log screen.
///
/// There used to be three of these — the dashboard's, the meals list's, and the
/// cards' own titles — at three sizes and weights, which is most of why the
/// screen read as noisy. Everything above a section now goes through here.
class LogSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LogSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.42 : 0.45),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.3,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          AppScaleTap(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                actionLabel!,
                style: AppTypography.labelSmall.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Individual card ──────────────────────────────────────────────────────────

/// One metric tile.
///
/// Every tile has the same four bands — label, value, a visual, a status line —
/// so a row of them reads as a table, not as four unrelated cards. The visual
/// band is the part that used to break: it reserved a sparkline's worth of
/// height and then painted nothing on a day with no data, leaving three of four
/// tiles mostly empty. It now falls back to a goal track, which is drawable at
/// zero and still says something true.
class HealthMetricCard extends StatelessWidget {
  /// Fixed so a row of tiles lines up. It has to clear the sum of the bands —
  /// 22 label + 10 + 27 value + 32 visual + 8 + ~14 status + 25 padding ≈ 138 —
  /// or the Column overflows; the Spacer takes up the slack.
  static const double height = 150;

  final HealthMetricCardData data;
  final VoidCallback onTap;

  const HealthMetricCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isPro = ref.watch(effectiveIsProProvider);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scheme = Theme.of(context).colorScheme;
        final textColor = scheme.onSurface;
        final accent = _metricAccentFor(context, data.type);
        final isLocked =
            !isPro &&
            (data.type == LogMetricType.protein ||
                data.type == LogMetricType.carbs ||
                data.type == LogMetricType.fat);

        final cardColor =
            isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white;

        final todayValue = data.values.isNotEmpty ? data.values.last : 0;
        final hasData = todayValue > 0;
        final hasWindowData = data.values.any((v) => v > 0);

        if (isLocked) {
          return _shell(
            context,
            isDark: isDark,
            cardColor: cardColor,
            onTap: () {
              PremiumConversionService().openPaywall(
                context,
                PaywallEntryPoint.macroDetails,
                featureName: 'macro_metrics',
              );
            },
            children: [
              _label(context, isDark: isDark, accent: accent, muted: true),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: 14,
                    color: isDark ? Colors.white38 : const Color(0xFFA8A29E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (AppLocalizations.of(context)?.common_unlock ?? 'Unlock'),
                    style: AppTypography.labelSmall.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Track(
                progress: 0,
                accent: accent,
                isDark: isDark,
                dashed: true,
              ),
              const SizedBox(height: 10),
            ],
          );
        }

        return _shell(
          context,
          isDark: isDark,
          cardColor: cardColor,
          onTap: onTap,
          children: [
            _label(context, isDark: isDark, accent: accent),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.displayLarge.copyWith(
                      // An empty day stays quiet; display weight is reserved
                      // for numbers the user actually earned.
                      color:
                          hasData ? textColor : textColor.withValues(alpha: 0.32),
                      fontWeight: FontWeight.w700,
                      fontSize: 27,
                      height: 1.0,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                if (data.unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    data.unit,
                    style: AppTypography.labelSmall.copyWith(
                      color: textColor.withValues(alpha: isDark ? 0.42 : 0.40),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            // The seven-day shape when there is one; otherwise the goal track,
            // which is honest at zero and keeps every tile the same shape.
            SizedBox(
              height: 32,
              child:
                  hasWindowData
                      ? HealthMetricMiniChart(
                        values: data.values,
                        goal: data.goal,
                        style: data.chartStyle,
                        accent: accent,
                        surfaceColor: cardColor,
                        isDark: isDark,
                      )
                      : Align(
                        alignment: Alignment.bottomCenter,
                        child: _Track(
                          progress: 0,
                          accent: accent,
                          isDark: isDark,
                          dashed: data.goal <= 0,
                        ),
                      ),
            ),
            const SizedBox(height: 8),
            Text(
              data.status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color:
                    hasData
                        ? accent.withValues(alpha: isDark ? 0.85 : 0.75)
                        : textColor.withValues(alpha: 0.38),
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _label(
    BuildContext context, {
    required bool isDark,
    required Color accent,
    bool muted = false,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: muted ? 0.08 : 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            data.icon,
            color: accent.withValues(alpha: muted ? 0.6 : 1),
            size: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: textColor.withValues(alpha: isDark ? 0.60 : 0.55),
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _shell(
    BuildContext context, {
    required bool isDark,
    required Color cardColor,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFEDE9E1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// The flat stand-in for the sparkline: a 5px goal track. Solid when there is a
/// target to move along, dashed when there is none, so "no target" and "no
/// progress" never look like the same thing.
class _Track extends StatelessWidget {
  final double progress;
  final Color accent;
  final bool isDark;
  final bool dashed;

  const _Track({
    required this.progress,
    required this.accent,
    required this.isDark,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dashed) {
      return SizedBox(
        height: 5,
        child: CustomPaint(
          painter: _DashedTrackPainter(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: isDark ? 0.16 : 0.12),
          ),
          size: Size.infinite,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.07),
          valueColor: AlwaysStoppedAnimation<Color>(accent),
        ),
      ),
    );
  }
}

class _DashedTrackPainter extends CustomPainter {
  final Color color;

  const _DashedTrackPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 5.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedTrackPainter old) => old.color != color;
}

// ── Bottom row (kept for compatibility, no longer used) ─────────────────────

// ── Mini chart ────────────────────────────────────────────────────────────────

class HealthMetricMiniChart extends StatelessWidget {
  final List<int> values;
  final int goal;
  final HealthMetricChartStyle style;
  final Color accent;
  final Color surfaceColor;
  final bool isDark;

  const HealthMetricMiniChart({
    super.key,
    required this.values,
    required this.goal,
    required this.style,
    required this.accent,
    required this.surfaceColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniChartPainter(
        values: values,
        goal: goal,
        style: style,
        accent: accent,
        guide: accent.withValues(alpha: isDark ? 0.22 : 0.16),
        dotBackground: surfaceColor,
        isDark: isDark,
      ),
      size: Size.infinite,
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<int> values;
  final int goal;
  final HealthMetricChartStyle style;
  final Color accent;
  final Color guide;
  final Color dotBackground;
  final bool isDark;

  const _MiniChartPainter({
    required this.values,
    required this.goal,
    required this.style,
    required this.accent,
    required this.guide,
    required this.dotBackground,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final data = values.isEmpty ? const [0] : values;
    // No tracked days, nothing drawn: a goal guide with zero data behind it
    // reads as progress that does not exist.
    if (!data.any((v) => v > 0)) return;
    final maxValue = math.max(goal, data.fold<int>(0, math.max));
    final yMax = math.max(maxValue, 1).toDouble();

    // Goal guide line (dashed)
    final guidePaint =
        Paint()
          ..color = guide
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
    const dashGap = 4.0;
    final yGoal = size.height - ((goal / yMax).clamp(0.0, 1.0) * size.height);
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, yGoal),
        Offset(math.min(x + dashWidth, size.width), yGoal),
        guidePaint,
      );
      x += dashWidth + dashGap;
    }

    if (style == HealthMetricChartStyle.line) {
      _paintLine(canvas, size, data, yMax);
    } else {
      _paintBars(canvas, size, data, yMax);
    }
  }

  void _paintBars(Canvas canvas, Size size, List<int> data, double yMax) {
    final count = data.length;
    final gap = count > 1 ? 4.0 : 0.0;
    final barWidth = (size.width - (gap * (count - 1))) / count;

    for (var index = 0; index < count; index++) {
      final normalized = (data[index] / yMax).clamp(0.0, 1.0);
      final height = math.max(3.0, normalized * size.height);
      final left = index * (barWidth + gap);
      final rect = Rect.fromLTWH(left, size.height - height, barWidth, height);
      final rRect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(barWidth / 2),
      );

      // Use gradient fill for bars
      final paint =
          Paint()
            ..shader = LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.55)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(rect);

      canvas.drawRRect(rRect, paint);
    }
  }

  void _paintLine(Canvas canvas, Size size, List<int> data, double yMax) {
    final points = <Offset>[];
    final usableHeight = size.height - 8;
    for (var index = 0; index < data.length; index++) {
      final x =
          data.length == 1
              ? size.width / 2
              : (size.width / (data.length - 1)) * index;
      final y =
          4 +
          usableHeight -
          ((data[index] / yMax).clamp(0.0, 1.0) * usableHeight);
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      // Build smooth path with cubic bezier segments
      final path = _buildSmoothPath(points);

      // Gradient area fill under the line
      final fillPath =
          Path.from(path)
            ..lineTo(points.last.dx, size.height)
            ..lineTo(points.first.dx, size.height)
            ..close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            colors: [
              accent.withValues(alpha: 0.30),
              accent.withValues(alpha: 0.00),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill,
      );

      // Line stroke
      canvas.drawPath(
        path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Dots for each point
    final bgPaint = Paint()..color = dotBackground.withValues(alpha: 0.90);
    final dotPaint = Paint()..color = accent;
    for (final point in points) {
      canvas.drawCircle(point, 4.5, bgPaint);
      canvas.drawCircle(point, 3.0, dotPaint);
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      path.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.goal != goal ||
        oldDelegate.style != style ||
        oldDelegate.accent != accent ||
        oldDelegate.guide != guide;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
