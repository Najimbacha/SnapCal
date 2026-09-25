import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../core/theme/app_motion.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/calorie_onboarding_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/motion/count_up_text.dart';
import 'onboarding_body.dart';
import 'onboarding_draft.dart';
import 'onboarding_kit.dart';
import 'onboarding_pace_calculator.dart';
import 'onboarding_units.dart';

/// How fast: three paces, each with its weekly rate and the day it gets
/// there, and a chart of the one chosen. Under 18, weight loss is gentle
/// only.
class PaceStep extends StatelessWidget {
  const PaceStep({
    super.key,
    required this.goal,
    required this.age,
    required this.pace,
    required this.currentKg,
    required this.targetKg,
    required this.system,
    required this.planFor,
    required this.onChanged,
    this.today,
  });

  final GoalType goal;
  final int age;
  final Pace pace;
  final double currentKg;
  final double targetKg;
  final MeasurementSystem system;

  /// The plan each pace would produce, from the same service that builds
  /// the final one, so the numbers shown here are the numbers saved.
  final OnboardingRecommendation Function(Pace pace) planFor;
  final ValueChanged<Pace> onChanged;

  /// For tests; defaults to now.
  final DateTime? today;

  DateTime? _finish(OnboardingRecommendation plan) {
    final days = daysToTarget(
      currentKg: currentKg,
      targetKg: targetKg,
      weeklyRateKg: plan.weeklyRateKg,
    );
    return days == null ? null : dateAfterDays(today ?? DateTime.now(), days);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dates = DateFormat.yMMMd(locale);
    final teenOnly = gentlePaceOnly(age: age, goal: goal);
    final unit =
        OnboardingPaceCalculator.weeklyRateUnit(system) == 'lb'
            ? l10n.settings_unit_lb
            : l10n.settings_unit_kg;
    final names = {
      Pace.gentle: l10n.onboarding_pace_gentle,
      Pace.balanced: l10n.onboarding_pace_balanced,
      Pace.faster: l10n.onboarding_pace_faster,
    };
    final chosen = planFor(pace);
    final chosenFinish = _finish(chosen);
    // The chart runs to the slowest pace's finish, so a faster pace ends
    // its line sooner and holds the target from there.
    int? daysAt(Pace p) => daysToTarget(
      currentKg: currentKg,
      targetKg: targetKg,
      weeklyRateKg: planFor(p).weeklyRateKg,
    );
    final longest = daysAt(Pace.gentle);
    final chosenDays = daysAt(pace);
    final reach =
        longest == null || chosenDays == null || longest <= 0
            ? 1.0
            : (chosenDays / longest).clamp(0.2, 1.0);

    return OnbPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnbQuestion(
            goal == GoalType.buildMuscle
                ? l10n.onb_q_pace_gain
                : l10n.onb_q_pace,
          ),
          const SizedBox(height: 22),
          for (final p in Pace.values) ...[
            if (p != Pace.gentle) const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final locked = teenOnly && p != Pace.gentle;
                final recommended =
                    teenOnly ? p == Pace.gentle : p == Pace.balanced;
                final rate = OnboardingPaceCalculator.weeklyRateKgFor(goal, p);
                final finish = locked ? null : _finish(planFor(p));
                return OnbOption(
                  key: ValueKey('onboarding-pace-${p.name}'),
                  entranceIndex: p.index,
                  selected: pace == p,
                  enabled: !locked,
                  showTick: false,
                  onTap: () => onChanged(p),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              names[p]!,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (recommended || locked) ...[
                              const SizedBox(height: 3),
                              Text(
                                locked
                                    ? l10n.onb_pace_adults_only
                                    : l10n.onboarding_pace_recommended
                                        .toUpperCase(),
                                style: TextStyle(
                                  color:
                                      locked
                                          ? context.textSecondaryColor
                                          : context.primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Shrinks and wraps on a narrow phone or in a longer
                      // language rather than pushing past the card.
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              textAlign: TextAlign.end,
                              l10n.onb_pace_per_week(
                                '${OnboardingPaceCalculator.formatWeeklyRateValue(rate, system)} $unit',
                              ),
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (finish != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                textAlign: TextAlign.end,
                                l10n.onb_pace_reach(dates.format(finish)),
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          if (teenOnly) ...[
            const SizedBox(height: 12),
            OnbNote(text: l10n.onb_pace_teen, tone: OnbTone.good),
          ],
          const SizedBox(height: 16),
          OnbCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUpText(
                  value: chosen.dailyCalories,
                  duration: const Duration(milliseconds: 700),
                  format:
                      (kcal) => l10n.onb_pace_kcal(
                        NumberFormat.decimalPattern(locale).format(kcal),
                      ),
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (chosenFinish != null) ...[
                  const SizedBox(height: 8),
                  ExcludeSemantics(
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      // Draws itself in once, then glides to each new
                      // finish as the pace changes.
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: AppMotion.maybeZero(
                          context,
                          const Duration(milliseconds: 1100),
                        ),
                        curve: Curves.easeInOutCubic,
                        builder:
                            (context, grow, _) => TweenAnimationBuilder<double>(
                              tween: Tween(end: reach),
                              duration: AppMotion.maybeZero(
                                context,
                                const Duration(milliseconds: 700),
                              ),
                              curve: AppMotion.springCurve,
                              builder:
                                  (context, reach, _) => CustomPaint(
                                    painter: _ProjectionPainter(
                                      grow: grow,
                                      reach: reach,
                                      start: kgToDisplay(currentKg, system),
                                      end: kgToDisplay(targetKg, system),
                                      unit: weightUnitLabel(l10n, system),
                                      startLabel: l10n.onb_chart_today,
                                      endLabel: dates.format(chosenFinish),
                                      line: context.primaryColor,
                                      surface: context.cardColor,
                                      grid: context.onbFill,
                                      strong: context.textPrimaryColor,
                                      muted: context.textSecondaryColor,
                                      textScaler: MediaQuery.textScalerOf(
                                        context,
                                      ),
                                      baseStyle:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium ??
                                          const TextStyle(),
                                    ),
                                  ),
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A straight line from today's weight to the target, to scale.
class _ProjectionPainter extends CustomPainter {
  _ProjectionPainter({
    required this.grow,
    required this.reach,
    required this.start,
    required this.end,
    required this.unit,
    required this.startLabel,
    required this.endLabel,
    required this.line,
    required this.surface,
    required this.grid,
    required this.strong,
    required this.muted,
    required this.textScaler,
    required this.baseStyle,
  });

  /// How much of the chart is drawn yet, 0 to 1, left to right.
  final double grow;

  /// Where along the width the target is reached, 0 to 1.
  final double reach;
  final double start;
  final double end;
  final String unit;
  final String startLabel;
  final String endLabel;
  final Color line;
  final Color surface;
  final Color grid;
  final Color strong;
  final Color muted;
  final TextScaler textScaler;

  /// The theme's body style, so the chart's words are in the app's
  /// typeface.
  final TextStyle baseStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0, right = 8.0, top = 30.0, bottom = 44.0;
    final lo = start < end ? start : end;
    final hi = start < end ? end : start;
    final pad = ((hi - lo) * 0.15).clamp(1.0, double.infinity);
    double y(double v) =>
        top +
        (1 - (v - (lo - pad)) / ((hi + pad) - (lo - pad))) *
            (size.height - top - bottom);
    final x0 = left, x1 = size.width - right;
    final xr = x0 + (x1 - x0) * reach;
    final y0 = y(start), y1 = y(end);
    final base = size.height - bottom;

    canvas.drawLine(Offset(x0, base), Offset(x1, base), Paint()..color = grid);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(0, 0, x0 + (x1 - x0 + right) * grow + 4, size.height),
    );
    final area =
        Path()
          ..moveTo(x0, y0)
          ..lineTo(xr, y1)
          ..lineTo(x1, y1)
          ..lineTo(x1, base)
          ..lineTo(x0, base)
          ..close();
    canvas.drawPath(area, Paint()..color = line.withValues(alpha: 0.12));
    canvas.drawPath(
      Path()
        ..moveTo(x0, y0)
        ..lineTo(xr, y1)
        ..lineTo(x1, y1),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
    canvas.drawCircle(Offset(x0, y0), 5, Paint()..color = surface);
    canvas.drawCircle(
      Offset(x0, y0),
      5,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // The finish dot and its words arrive once the line has reached it.
    final settled = grow >= 1 ? 1.0 : ((grow - reach) * 6).clamp(0.0, 1.0);
    if (settled > 0) {
      canvas.drawCircle(Offset(xr, y1), 6.5 * settled, Paint()..color = line);
    }

    /// Paints [s] and returns where its right edge ended up.
    double text(
      String s,
      Offset at, {
      required bool alignEnd,
      required TextStyle style,
      bool centred = false,
      double minX = 0,
    }) {
      final painter = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      var dx =
          centred
              ? at.dx - painter.width / 2
              : (alignEnd ? at.dx - painter.width : at.dx);
      final maxX = (size.width - painter.width).clamp(0.0, size.width);
      dx = dx.clamp(minX.clamp(0.0, maxX), maxX);
      painter.paint(canvas, Offset(dx, at.dy));
      final right = dx + painter.width;
      painter.dispose();
      return right;
    }

    final bold = baseStyle.copyWith(
      color: strong,
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
    );
    final small = baseStyle.copyWith(color: muted, fontSize: 11.5);
    // Each weight goes on the side of its dot away from the line.
    text(
      '${start.toStringAsFixed(1)} $unit',
      Offset(x0, y0 < y1 ? y0 - 24 : y0 + 10),
      alignEnd: false,
      style: bold,
    );
    final todayEnd = text(
      startLabel,
      Offset(x0, size.height - 18),
      alignEnd: false,
      style: small,
    );
    if (settled > 0) {
      text(
        '${end.toStringAsFixed(1)} $unit',
        Offset(xr, y1 < y0 ? y1 - 24 : y1 + 10),
        alignEnd: true,
        centred: reach < 1,
        style: bold.copyWith(
          color: strong.withValues(alpha: settled * strong.a),
        ),
      );
      text(
        endLabel,
        Offset(xr, size.height - 18),
        alignEnd: true,
        centred: reach < 1,
        minX: todayEnd + 10,
        style: small.copyWith(
          color: muted.withValues(alpha: settled * muted.a),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_ProjectionPainter old) =>
      old.grow != grow ||
      old.reach != reach ||
      old.start != start ||
      old.end != end ||
      old.unit != unit ||
      old.endLabel != endLabel ||
      old.line != line ||
      old.strong != strong ||
      old.muted != muted ||
      old.surface != surface ||
      old.grid != grid ||
      old.textScaler != textScaler ||
      old.baseStyle != baseStyle;
}
