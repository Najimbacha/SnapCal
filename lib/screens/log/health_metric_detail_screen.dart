import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../data/models/activity_summary.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/activity_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/water_provider.dart';
import '../../widgets/ui_blocks.dart';
import 'models/log_metric_models.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

const _minimalBg = Color(0xFFF9F8F5);
const _minimalDarkBg = Color(0xFF14130F);
const _minimalInk = Color(0xFF1C1917);
const _minimalLine = Color(0xFFE8E4DC);
const _minimalGreen = Color(0xFF1A3D2B);
const _minimalGreenText = Color(0xFF16733A);

class HealthMetricDetailScreen extends StatefulWidget {
  final LogMetricType metric;

  const HealthMetricDetailScreen({super.key, required this.metric});

  @override
  State<HealthMetricDetailScreen> createState() =>
      _HealthMetricDetailScreenState();
}

class _HealthMetricDetailScreenState extends State<HealthMetricDetailScreen> {
  LogMetricPeriod _period = LogMetricPeriod.week;
  DateTime _anchor = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _minimalDarkBg : _minimalBg;
    final accent = _metricAccentFor(widget.metric);

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: bg,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: bg,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: FutureBuilder<_MetricDetailData>(
            future: _buildData(context),
            builder: (context, snapshot) {
              final data = snapshot.data;
              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 8,
                  20,
                  88,
                ),
                children: [
                  _DetailHeader(
                    title: _metricTitle(l10n, widget.metric),
                    accent: accent,
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/log');
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  _PeriodSelector(
                    selected: _period,
                    accent: accent,
                    onChanged: (period) => setState(() {
                      _period = period;
                    }),
                  ),
                  const SizedBox(height: 20),
                  _PeriodNavigation(
                    title: _periodTitle(l10n, _period),
                    canMoveNext: canMoveMetricPeriodForward(_period, _anchor),
                    onPrevious: () => setState(() {
                      _anchor = shiftMetricAnchor(_period, _anchor, -1);
                    }),
                    onNext: () => setState(() {
                      _anchor = shiftMetricAnchor(_period, _anchor, 1);
                    }),
                    onCalendar: _pickAnchorDate,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      data == null)
                    _MetricDetailLoading(accent: accent)
                  else if (data != null) ...[
                    _MetricHero(data: data, accent: accent, isDark: isDark),
                    const SizedBox(height: 20),
                    // Chart card
                    Container(
                      height: 248,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0x00FFFFFF),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : _minimalLine,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                      child: _HealthMetricDetailChart(
                        data: data,
                        accent: accent,
                        isDark: isDark,
                        isPro: data.isPro,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Section header
                    _SectionHeader(
                      title: l10n.log_metric_detail_list_title,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _MetricPointList(
                      data: data,
                      accent: accent,
                      isDark: isDark,
                      isPro: data.isPro,
                      onLockedTap: _openHistoryPaywall,
                      onUpgradeTap: _openHistoryPaywall,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickAnchorDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          normalizeMetricDate(_anchor).isAfter(DateTime.now())
              ? DateTime.now()
              : _anchor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _anchor = picked;
    });
  }

  Future<_MetricDetailData> _buildData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final mealProvider = context.read<MealProvider>();
    final settings = context.read<SettingsProvider>();
    final water = context.read<WaterProvider>();
    final activity = context.read<ActivityProvider>();
    final range = metricRangeFor(_period, _anchor);
    final buckets = metricBucketsFor(_period, _anchor);
    final needsActivity =
        widget.metric == LogMetricType.energy ||
        widget.metric == LogMetricType.steps;

    final activitySummaries = needsActivity
        ? await activity.fetchSummariesForRange(range.start, range.end)
        : <ActivitySummary>[];
    final activityByDate = {
      for (final summary in activitySummaries)
        metricDateString(summary.date): summary,
    };

    final points = <MetricPoint>[];
    var totalValue = 0;
    var elapsedDays = 0;

    for (final bucket in buckets) {
      var value = 0;
      var goal = 0;
      var locked = false;
      var bucketElapsedDays = 0;

      for (final day in eachMetricDay(bucket.start, bucket.end)) {
        final today = normalizeMetricDate(DateTime.now());
        if (day.isAfter(today)) {
          goal += _dailyGoal(widget.metric, settings, water, activity);
          continue;
        }

        bucketElapsedDays++;
        final dateString = metricDateString(day);
        goal += _dailyGoal(widget.metric, settings, water, activity);
        if (isMetricDateLocked(
          widget.metric,
          dateString,
          (date) => mealProvider.canViewDate(date, isPro: settings.isPro),
        )) {
          locked = true;
          continue;
        }

        final summary = activityByDate[dateString];
        value += _valueForDate(
          type: widget.metric,
          dateString: dateString,
          mealProvider: mealProvider,
          water: water,
          activitySummary: summary,
        );
      }

      totalValue += value;
      elapsedDays += bucketElapsedDays;
      points.add(
        MetricPoint(
          start: bucket.start,
          end: bucket.end,
          value: value,
          goal: goal,
          locked: locked,
        ),
      );
    }

    final average = elapsedDays == 0 ? 0 : (totalValue / elapsedDays).round();
    final dailyGoal = _dailyGoal(widget.metric, settings, water, activity);
    final unit = _unitForMetric(l10n, widget.metric);
    return _MetricDetailData(
      type: widget.metric,
      period: _period,
      points: points,
      averageValue: average,
      totalValue: totalValue,
      dailyGoal: dailyGoal,
      unit: unit,
      perDayUnit:
          widget.metric == LogMetricType.steps
              ? l10n.log_metric_steps_unit
              : unit,
      title: _metricTitle(l10n, widget.metric),
      periodTitle: _periodTitle(l10n, _period),
      goalStatus:
          average >= dailyGoal
              ? l10n.log_metric_goal_hit
              : l10n.log_metric_goal_miss,
      localeName: locale,
      isPro: settings.isPro,
    );
  }

  void _openHistoryPaywall() {
    PremiumConversionService().openPaywall(
      context,
      PaywallEntryPoint.reportInsight,
      featureName: 'full_history',
    );
  }
}

// ── Section header label ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? Colors.white54 : const Color(0xFFB4AFA8),
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ── Detail header ─────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final String title;
  final Color accent;
  final VoidCallback onBack;

  const _DetailHeader({
    required this.title,
    required this.accent,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE8E4DC).withValues(alpha: 0.56);

    return Row(
      children: [
        AppScaleTap(
          onTap: onBack,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              size: 20,
              color: _healthText(context).withValues(alpha: 0.88),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTypography.heading2.copyWith(
              color: _healthText(context),
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: chipColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(
            LucideIcons.moreHorizontal,
            size: 20,
            color: _healthText(context).withValues(alpha: 0.54),
          ),
        ),
      ],
    );
  }
}

// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final LogMetricPeriod selected;
  final Color accent;
  final ValueChanged<LogMetricPeriod> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFE8E4DC).withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: LogMetricPeriod.values.map((period) {
          final active = selected == period;
          return Expanded(
            child: AppScaleTap(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? accent : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _periodCode(l10n, period),
                  style: AppTypography.titleMedium.copyWith(
                    color: active
                        ? Colors.white
                        : _healthText(context).withValues(alpha: 0.52),
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Period navigation ─────────────────────────────────────────────────────────

class _PeriodNavigation extends StatelessWidget {
  final String title;
  final bool canMoveNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCalendar;
  final bool isDark;

  const _PeriodNavigation({
    required this.title,
    required this.canMoveNext,
    required this.onPrevious,
    required this.onNext,
    required this.onCalendar,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.heading2.copyWith(
                  color: _healthText(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _NavChip(
          icon: LucideIcons.chevronLeft,
          onTap: onPrevious,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _NavChip(
          icon: LucideIcons.chevronRight,
          onTap: canMoveNext ? onNext : null,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _NavChip(
          icon: LucideIcons.calendarDays,
          onTap: onCalendar,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _NavChip({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE8E4DC).withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.09)
                : Colors.black.withValues(alpha: 0.07),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: _healthText(context)
              .withValues(alpha: enabled ? 0.72 : 0.22),
        ),
      ),
    );
  }
}

// ── Hero stats ────────────────────────────────────────────────────────────────

class _MetricHero extends StatelessWidget {
  final _MetricDetailData data;
  final Color accent;
  final bool isDark;

  const _MetricHero({
    required this.data,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = _formatInt(context, data.averageValue);
    final progress = data.dailyGoal > 0
        ? (data.averageValue / data.dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    final isGoalHit = data.averageValue >= data.dailyGoal;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0x00FFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : _minimalLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        number,
                        style: AppTypography.displayLarge.copyWith(
                          color: _healthText(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 48,
                          height: 0.95,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          l10n.log_metric_per_day_avg(data.perDayUnit),
                          style: AppTypography.titleLarge.copyWith(
                            color: _healthText(context).withValues(alpha: 0.60),
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Goal hit badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isGoalHit
                      ? accent.withValues(alpha: 0.10)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isGoalHit
                        ? accent.withValues(alpha: 0.28)
                        : Colors.orange.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGoalHit
                          ? LucideIcons.checkCircle2
                          : LucideIcons.target,
                      size: 12,
                      color: isGoalHit ? accent : Colors.orange,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      data.goalStatus,
                      style: AppTypography.labelSmall.copyWith(
                        color: isGoalHit ? accent : Colors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress towards daily goal
          Row(
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.labelSmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(
                          color: accent.withValues(
                              alpha: isDark ? 0.18 : 0.12),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(color: accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatInt(context, data.dailyGoal)} goal',
                style: AppTypography.labelSmall.copyWith(
                  color: _healthText(context).withValues(alpha: 0.48),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chart ─────────────────────────────────────────────────────────────────────

class _HealthMetricDetailChart extends StatelessWidget {
  final _MetricDetailData data;
  final Color accent;
  final bool isDark;
  final bool isPro;

  const _HealthMetricDetailChart({
    required this.data,
    required this.accent,
    required this.isDark,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetailChartPainter(
        points: data.points,
        accent: accent,
        labelColor: _healthText(context).withValues(alpha: 0.55),
        guideColor: accent.withValues(alpha: 0.55),
        localeName: data.localeName,
        isDark: isDark,
        isPro: isPro,
      ),
      size: Size.infinite,
    );
  }
}

class _DetailChartPainter extends CustomPainter {
  final List<MetricPoint> points;
  final Color accent;
  final Color labelColor;
  final Color guideColor;
  final String localeName;
  final bool isDark;
  final bool isPro;

  const _DetailChartPainter({
    required this.points,
    required this.accent,
    required this.labelColor,
    required this.guideColor,
    required this.localeName,
    required this.isDark,
    required this.isPro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || points.isEmpty) return;
    const rightGutter = 56.0;
    const bottomGutter = 32.0;
    final chartW = size.width - rightGutter;
    final chartH = size.height - bottomGutter;

    final maxValue = points.fold<int>(0, (max, p) {
      return math.max(max, math.max(p.value, p.goal));
    });
    final yMax = math.max(maxValue, 1).toDouble();
    final topGoal = points.fold<int>(0, (m, p) => math.max(m, p.goal));

    // Horizontal grid lines
    final gridLabels = [topGoal, (topGoal * 2 / 3).round(), (topGoal / 3).round(), 0];
    for (final label in gridLabels) {
      final y = chartH - ((label / yMax).clamp(0.0, 1.0) * chartH);
      // Grid line
      canvas.drawLine(
        Offset(0, y),
        Offset(chartW, y),
        Paint()
          ..color = (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.06)
          ..strokeWidth = 1,
      );
      // Right-side label
      _drawText(
        canvas,
        _compactNumber(label, localeName),
        Offset(chartW + 8, y - 9),
        labelColor,
        11,
        FontWeight.w700,
      );
    }

    // Goal line — dashed
    final goalY = chartH - ((topGoal / yMax).clamp(0.0, 1.0) * chartH);
    _drawDashedLine(
      canvas,
      Offset(0, goalY),
      Offset(chartW, goalY),
      Paint()
        ..color = guideColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Bars
    final count = points.length;
    final gap = count <= 1
        ? 0.0
        : count <= 7
            ? 10.0
            : count <= 13
                ? 6.0
                : 3.0;
    final maxBarWidth = count <= 7 ? 36.0 : 16.0;
    final availW = math.max(0.0, chartW - (gap * (count - 1)));
    final barWidth = math.min(maxBarWidth, availW / count);
    if (barWidth <= 0) return;

    final totalW = barWidth * count + gap * (count - 1);
    final startX = math.max(0.0, (chartW - totalW) / 2);

    for (var i = 0; i < count; i++) {
      final point = points[i];
      final normalized = (point.value / yMax).clamp(0.0, 1.0);
      final barH = point.value == 0
          ? 4.0
          : math.max(8.0, normalized * chartH);
      final left = startX + i * (barWidth + gap);
      final rect = Rect.fromLTWH(left, chartH - barH, barWidth, barH);
      final rRect =
          RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2));

      final isLocked = point.locked;

      if (isLocked && !isPro) {
        // ── Free user: heavily muted + frosted look ──
        // Draw a very faint stub bar (25% height minimum so it's visible)
        final stubH = math.max(barH * 0.4, 14.0);
        final stubRect = Rect.fromLTWH(
            left, chartH - stubH, barWidth, stubH);
        final stubRRect = RRect.fromRectAndRadius(
            stubRect, Radius.circular(barWidth / 2));
        canvas.drawRRect(
          stubRRect,
          Paint()
            ..shader = LinearGradient(
              colors: [
                accent.withValues(alpha: 0.18),
                accent.withValues(alpha: 0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(stubRect),
        );
        // Hatching lines to reinforce locked state
        final hatchPaint = Paint()
          ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
          ..strokeWidth = 1.5;
        var hx = left;
        while (hx < left + barWidth + stubH) {
          canvas.drawLine(
            Offset(hx, chartH),
            Offset(hx - stubH, chartH - stubH),
            hatchPaint,
          );
          hx += 5;
        }
      } else {
        // ── Normal bar (unlocked or pro) ──
        canvas.drawRRect(
          rRect,
          Paint()
            ..shader = LinearGradient(
              colors: isLocked
                  ? [
                      accent.withValues(alpha: 0.28),
                      accent.withValues(alpha: 0.14),
                    ]
                  : [accent, accent.withValues(alpha: 0.55)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(rect),
        );
      }

      // X-axis label
      final label = _shortPointLabel(point, i, count, localeName);
      if (label.isNotEmpty) {
        _drawText(
          canvas,
          label,
          Offset(left + barWidth / 2, chartH + 10),
          isLocked && !isPro
              ? labelColor.withValues(alpha: 0.35)
              : labelColor,
          11,
          FontWeight.w700,
          center: true,
        );
      }
    }
  }

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLen = 5.0;
    const gapLen = 4.0;
    double dist = 0;
    final total = (end.dx - start.dx).abs();
    while (dist < total) {
      canvas.drawLine(
        Offset(start.dx + dist, start.dy),
        Offset(start.dx + math.min(dist + dashLen, total), end.dy),
        paint,
      );
      dist += dashLen + gapLen;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
    FontWeight weight, {
    bool center = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center ? Offset(offset.dx - painter.width / 2, offset.dy) : offset,
    );
  }

  @override
  bool shouldRepaint(covariant _DetailChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.accent != accent ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.isPro != isPro;
  }
}

// ── Period list ───────────────────────────────────────────────────────────────

class _MetricPointList extends StatelessWidget {
  final _MetricDetailData data;
  final Color accent;
  final bool isDark;
  final bool isPro;
  final VoidCallback onLockedTap;
  final VoidCallback onUpgradeTap;

  const _MetricPointList({
    required this.data,
    required this.accent,
    required this.isDark,
    required this.isPro,
    required this.onLockedTap,
    required this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final reversed = data.points.reversed.toList();
    // Find the index of the first locked row (oldest shown)
    final firstLockedIndex = reversed.indexWhere((p) => p.locked);
    final hasLockedRows = firstLockedIndex >= 0;

    final rows = List.generate(reversed.length, (index) {
      final point = reversed[index];
      final locked = point.locked;
      final progress = data.dailyGoal > 0
          ? (point.value / data.dailyGoal).clamp(0.0, 1.0)
          : 0.0;
      final isFirst = index == 0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppScaleTap(
          onTap: locked ? onLockedTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: isFirst ? 0.06 : 0.035)
                  : (isFirst
                      ? Colors.white.withValues(alpha: 0.18)
                      : const Color(0x00FFFFFF)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFirst
                    ? accent.withValues(alpha: isDark ? 0.20 : 0.18)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : _minimalLine),
              ),
            ),
            child: Row(
              children: [
                // Accent dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: locked
                        ? _healthText(context).withValues(alpha: 0.18)
                        : (isFirst
                            ? accent
                            : accent.withValues(alpha: 0.34)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pointLabel(context, point, data),
                        style: AppTypography.titleMedium.copyWith(
                          color: _healthText(context)
                              .withValues(alpha: isFirst ? 0.92 : 0.68),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!locked && data.dailyGoal > 0) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            height: 3,
                            child: Stack(
                              children: [
                                Container(
                                  color: accent.withValues(
                                      alpha: isDark ? 0.14 : 0.10),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    color: accent.withValues(
                                        alpha: isFirst ? 0.90 : 0.50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (locked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE8E4DC).withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      LucideIcons.lock,
                      size: 14,
                      color: _healthText(context).withValues(alpha: 0.40),
                    ),
                  )
                else
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _formatInt(context, point.value),
                          style: AppTypography.heading3.copyWith(
                            color: isFirst
                                ? accent
                                : _healthText(context),
                            fontWeight: FontWeight.w800,
                            fontSize: isFirst ? 22 : 19,
                            letterSpacing: 0,
                          ),
                        ),
                        if (data.unit.isNotEmpty)
                          TextSpan(
                            text: ' ${data.unit}',
                            style: AppTypography.labelMedium.copyWith(
                              color: _healthText(context)
                                  .withValues(alpha: 0.52),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });

    return Column(
      children: [
        ...rows,
        // ── Upgrade cliff banner (free users only, when there are locked rows) ──
        if (!isPro && hasLockedRows)
          _UpgradeCliffBanner(
            accent: accent,
            isDark: isDark,
            onTap: onUpgradeTap,
          ),
      ],
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _MetricDetailLoading extends StatelessWidget {
  final Color accent;

  const _MetricDetailLoading({required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    Widget shimmerBox({
      required double height,
      double? width,
      double radius = 16,
    }) {
      return Container(
        height: height,
        width: width,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 1400.ms,
            color: (isDark ? Colors.white : Colors.white)
                .withValues(alpha: 0.08),
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shimmerBox(height: 100, radius: 24),
        shimmerBox(height: 248, radius: 24),
        shimmerBox(height: 22, width: 120, radius: 8),
        const SizedBox(height: 4),
        ...List.generate(4, (_) => shimmerBox(height: 64, radius: 18)),
      ],
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _MetricDetailData {
  final LogMetricType type;
  final LogMetricPeriod period;
  final List<MetricPoint> points;
  final int averageValue;
  final int totalValue;
  final int dailyGoal;
  final String unit;
  final String perDayUnit;
  final String title;
  final String periodTitle;
  final String goalStatus;
  final String localeName;
  final bool isPro;

  const _MetricDetailData({
    required this.type,
    required this.period,
    required this.points,
    required this.averageValue,
    required this.totalValue,
    required this.dailyGoal,
    required this.unit,
    required this.perDayUnit,
    required this.title,
    required this.periodTitle,
    required this.goalStatus,
    required this.localeName,
    required this.isPro,
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

int _valueForDate({
  required LogMetricType type,
  required String dateString,
  required MealProvider mealProvider,
  required WaterProvider water,
  ActivitySummary? activitySummary,
}) {
  switch (type) {
    case LogMetricType.water:
      return water.getTotalForDate(dateString);
    case LogMetricType.energy:
      final summary = activitySummary;
      if (summary == null) return 0;
      return summary.activityCalories + summary.manualWorkoutCalories;
    case LogMetricType.steps:
      return activitySummary?.steps ?? 0;
    case LogMetricType.calories:
      return mealProvider
          .getMealsForDate(dateString)
          .fold<int>(0, (sum, meal) => sum + meal.calories);
    case LogMetricType.carbs:
      return mealProvider
          .getMealsForDate(dateString)
          .fold<int>(0, (sum, meal) => sum + meal.macros.carbs);
    case LogMetricType.fat:
      return mealProvider
          .getMealsForDate(dateString)
          .fold<int>(0, (sum, meal) => sum + meal.macros.fat);
    case LogMetricType.protein:
      return mealProvider
          .getMealsForDate(dateString)
          .fold<int>(0, (sum, meal) => sum + meal.macros.protein);
  }
}

int _dailyGoal(
  LogMetricType type,
  SettingsProvider settings,
  WaterProvider water,
  ActivityProvider activity,
) {
  switch (type) {
    case LogMetricType.water:
      return water.goal;
    case LogMetricType.energy:
      return (activity.stepGoal * 0.04).round();
    case LogMetricType.steps:
      return activity.stepGoal;
    case LogMetricType.calories:
      return settings.dailyCalorieGoal;
    case LogMetricType.carbs:
      return settings.dailyCarbGoal;
    case LogMetricType.fat:
      return settings.dailyFatGoal;
    case LogMetricType.protein:
      return settings.dailyProteinGoal;
  }
}

String _metricTitle(AppLocalizations l10n, LogMetricType type) {
  switch (type) {
    case LogMetricType.water:
      return l10n.log_metric_water;
    case LogMetricType.energy:
      return l10n.log_metric_energy_burned;
    case LogMetricType.steps:
      return l10n.log_metric_steps;
    case LogMetricType.calories:
      return l10n.log_metric_calories_intake;
    case LogMetricType.carbs:
      return l10n.log_metric_carbs;
    case LogMetricType.fat:
      return l10n.log_metric_fat;
    case LogMetricType.protein:
      return l10n.log_metric_protein;
  }
}

String _unitForMetric(AppLocalizations l10n, LogMetricType type) {
  switch (type) {
    case LogMetricType.water:
      return 'ml';
    case LogMetricType.energy:
    case LogMetricType.calories:
      return 'cal';
    case LogMetricType.steps:
      return '';
    case LogMetricType.carbs:
    case LogMetricType.fat:
    case LogMetricType.protein:
      return l10n.settings_grams_unit;
  }
}

String _periodCode(AppLocalizations l10n, LogMetricPeriod period) {
  switch (period) {
    case LogMetricPeriod.day:
      return l10n.log_period_day;
    case LogMetricPeriod.week:
      return l10n.log_period_week;
    case LogMetricPeriod.month:
      return l10n.log_period_month;
    case LogMetricPeriod.threeMonths:
      return l10n.log_period_three_months;
    case LogMetricPeriod.year:
      return l10n.log_period_year;
  }
}

String _periodTitle(AppLocalizations l10n, LogMetricPeriod period) {
  switch (period) {
    case LogMetricPeriod.day:
      return l10n.log_detail_this_day;
    case LogMetricPeriod.week:
      return l10n.log_detail_this_week;
    case LogMetricPeriod.month:
      return l10n.log_detail_this_month;
    case LogMetricPeriod.threeMonths:
      return l10n.log_detail_this_three_months;
    case LogMetricPeriod.year:
      return l10n.log_detail_this_year;
  }
}

String _pointLabel(
  BuildContext context,
  MetricPoint point,
  _MetricDetailData data,
) {
  final l10n = AppLocalizations.of(context)!;
  if (point.start == point.end) {
    return app_date.DateUtils.getDateLabel(
      metricDateString(point.start),
      l10n: l10n,
      localeName: data.localeName,
    );
  }
  if (data.period == LogMetricPeriod.year) {
    return DateFormat.MMM(data.localeName).format(point.start);
  }
  final formatter = DateFormat.MMMd(data.localeName);
  return '${formatter.format(point.start)} - ${formatter.format(point.end)}';
}

String _shortPointLabel(
  MetricPoint point,
  int index,
  int count,
  String localeName,
) {
  if (count <= 7 && point.start == point.end) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[point.start.weekday - 1];
  }
  if (count <= 12 && point.start.day == 1) {
    return DateFormat.MMM(localeName).format(point.start).substring(0, 1);
  }
  if (count <= 13) {
    return index.isEven ? '${point.start.day}' : '';
  }
  final day = point.start.day;
  final isLast = index == count - 1;
  if (day == 1 || day == 8 || day == 15 || day == 22 || isLast) {
    return '$day';
  }
  return '';
}

String _formatInt(BuildContext context, int value) {
  return NumberFormat.decimalPattern(
    AppLocalizations.of(context)?.localeName,
  ).format(value);
}

String _compactNumber(int value, String localeName) {
  return NumberFormat.decimalPattern(localeName).format(value);
}

Color _metricAccentFor(LogMetricType type) {
  return _minimalGreenText;
}

Color _healthText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : _minimalInk;
}

class _UpgradeCliffBanner extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _UpgradeCliffBanner({
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _minimalGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF86EFAC).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.lock,
                color: const Color(0xFF86EFAC),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Full History Locked',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF0FDF4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Upgrade to Pro to view history beyond 14 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF86EFAC),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: const Color(0xFF86EFAC),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
