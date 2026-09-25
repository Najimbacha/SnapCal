import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../core/theme/theme_colors.dart';
import '../../data/services/calorie_onboarding_service.dart';
import '../../l10n/generated/app_localizations.dart';
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
                Text(
                  l10n.onb_pace_kcal(
                    NumberFormat.decimalPattern(
                      locale,
                    ).format(chosen.dailyCalories),
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
                      child: CustomPaint(
                        painter: _ProjectionPainter(
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
                          textScaler: MediaQuery.textScalerOf(context),
                          baseStyle:
                              Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle(),
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
    final y0 = y(start), y1 = y(end);
    final base = size.height - bottom;

    canvas.drawLine(Offset(x0, base), Offset(x1, base), Paint()..color = grid);
    final area =
        Path()
          ..moveTo(x0, y0)
          ..lineTo(x1, y1)
          ..lineTo(x1, base)
          ..lineTo(x0, base)
          ..close();
    canvas.drawPath(area, Paint()..color = line.withValues(alpha: 0.12));
    canvas.drawLine(
      Offset(x0, y0),
      Offset(x1, y1),
      Paint()
        ..color = line
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(x0, y0), 5, Paint()..color = surface);
    canvas.drawCircle(
      Offset(x0, y0),
      5,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(Offset(x1, y1), 6.5, Paint()..color = line);

    void text(
      String s,
      Offset at, {
      required bool alignEnd,
      required TextStyle style,
    }) {
      final painter = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      painter.paint(
        canvas,
        Offset(alignEnd ? at.dx - painter.width : at.dx, at.dy),
      );
      painter.dispose();
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
    text(
      '${end.toStringAsFixed(1)} $unit',
      Offset(x1, y1 < y0 ? y1 - 24 : y1 + 10),
      alignEnd: true,
      style: bold,
    );
    text(
      startLabel,
      Offset(x0, size.height - 18),
      alignEnd: false,
      style: small,
    );
    text(endLabel, Offset(x1, size.height - 18), alignEnd: true, style: small);
  }

  @override
  bool shouldRepaint(_ProjectionPainter old) =>
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
