import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_typography.dart';
import '../../../widgets/ui_blocks.dart';
import '../models/log_metric_models.dart';
import '../../../data/services/premium_conversion_service.dart';
import '../../../providers/settings_provider.dart';

enum HealthMetricChartStyle { bars, line }

const _minimalInk = Color(0xFF1C1917);
const _minimalGreen = Color(0xFF1A3D2B);
const _minimalGreenText = Color(0xFF16733A);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? Colors.white54 : const Color(0xFFB4AFA8),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
            _CustomizeButton(
              label: actionLabel,
              isDark: isDark,
              onTap: onCustomize,
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final cardWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: cardWidth,
                      child: HealthMetricCard(
                        data: card,
                        onTap: () => onMetricTap(card.type),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Customize button ─────────────────────────────────────────────────────────

class _CustomizeButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _CustomizeButton({
    required this.label,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = _minimalGreenText;
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

// ── Individual card ──────────────────────────────────────────────────────────

class HealthMetricCard extends StatelessWidget {
  final HealthMetricCardData data;
  final VoidCallback onTap;

  const HealthMetricCard({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _minimalInk;
    const accent = _minimalGreen;

    final isPro = context.watch<SettingsProvider>().isPro;
    final isLocked = !isPro && (data.type == LogMetricType.protein ||
        data.type == LogMetricType.carbs ||
        data.type == LogMetricType.fat);

    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.045)
        : const Color(0x00FFFFFF);

    // Progress fraction (capped at 1.0)
    final todayValue =
        data.values.isNotEmpty ? data.values.last : 0;
    final progress =
        data.goal > 0 ? (todayValue / data.goal).clamp(0.0, 1.0) : 0.0;
    final hasData = todayValue > 0;

    return AppScaleTap(
      onTap: () {
        if (isLocked) {
          PremiumConversionService().openPaywall(
            context,
            PaywallEntryPoint.settings,
            featureName: 'macro_metrics',
          );
        } else {
          onTap();
        }
      },
      child: Container(
        height: 158,
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE8E4DC),
            width: 1.0,
          ),
        ),
        child: Stack(
          children: [
            Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF78716C),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Arc progress + icon badge
                        _ArcIconBadge(
                          icon: data.icon,
                          accent: accent,
                          progress: progress,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          data.value,
                          style: AppTypography.displayLarge.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 27,
                            height: 1.0,
                            letterSpacing: 0,
                          ),
                        ),
                        if (data.unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              data.unit,
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFFA8A29E),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: HealthMetricMiniChart(
                        values: data.values,
                        goal: data.goal,
                        style: data.chartStyle,
                        accent: accent,
                        surfaceColor: cardColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _BottomRow(
                      status: data.status,
                      progress: progress,
                      accent: accent,
                      hasData: hasData,
                      textColor: textColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              if (isLocked)
              Positioned(
                  top: 44,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                      child: Container(
                        color: (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: isDark ? 0.48 : 0.50),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _minimalGreen,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.lock,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'UNLOCK',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
        ),
      ),
    );
  }
}

// ── Arc icon badge ────────────────────────────────────────────────────────────

class _ArcIconBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final double progress;
  final bool isDark;

  const _ArcIconBadge({
    required this.icon,
    required this.accent,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(
          progress: progress,
          accent: accent,
          isDark: isDark,
        ),
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.20 : 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 15),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final bool isDark;

  const _ArcPainter({
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    const startAngle = -math.pi / 2;

    // Track arc
    canvas.drawArc(
      rect,
      startAngle,
      2 * math.pi,
      false,
      Paint()
        ..color = accent.withValues(alpha: isDark ? 0.16 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      // Progress arc
      canvas.drawArc(
        rect,
        startAngle,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

// ── Bottom row: progress bar + label ─────────────────────────────────────────

class _BottomRow extends StatelessWidget {
  final String status;
  final double progress;
  final Color accent;
  final bool hasData;
  final Color textColor;
  final bool isDark;

  const _BottomRow({
    required this.status,
    required this.progress,
    required this.accent,
    required this.hasData,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thin linear progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                // Track
                Container(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                ),
                // Fill
                if (hasData)
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent,
                            accent.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        // Status label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: hasData
                ? accent.withValues(alpha: isDark ? 0.18 : 0.10)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            style: AppTypography.labelSmall.copyWith(
              color: hasData
                  ? accent
                  : textColor.withValues(alpha: 0.50),
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

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
    final maxValue = math.max(goal, data.fold<int>(0, math.max));
    final yMax = math.max(maxValue, 1).toDouble();

    // Goal guide line (dashed)
    final guidePaint = Paint()
      ..color = guide
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
    const dashGap = 4.0;
    final yGoal =
        size.height - ((goal / yMax).clamp(0.0, 1.0) * size.height);
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
      final rRect =
          RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2));

      // Use gradient fill for bars
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            accent,
            accent.withValues(alpha: 0.55),
          ],
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
      final x = data.length == 1
          ? size.width / 2
          : (size.width / (data.length - 1)) * index;
      final y = 4 +
          usableHeight -
          ((data[index] / yMax).clamp(0.0, 1.0) * usableHeight);
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      // Build smooth path with cubic bezier segments
      final path = _buildSmoothPath(points);

      // Gradient area fill under the line
      final fillPath = Path.from(path)
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
