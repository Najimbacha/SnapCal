import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/models/meal.dart';
import '../../../l10n/generated/app_localizations.dart';

const _sage = Color(0xFF82A789);
const _blue = Color(0xFF6B9BCB);
const _amber = Color(0xFFD6A14F);

class _Chevron extends StatelessWidget {
  const _Chevron();
  @override
  Widget build(BuildContext context) => Icon(
    Directionality.of(context) == TextDirection.rtl
        ? LucideIcons.chevronLeft
        : LucideIcons.chevronRight,
    size: 16,
  );
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({required this.coach, required this.color});
  final bool coach;
  final Color color;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(28, 30),
    painter: _ToolIconPainter(coach, color),
  );
}

class _ToolIconPainter extends CustomPainter {
  const _ToolIconPainter(this.coach, this.color);
  final bool coach;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final pen =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round;
    if (!coach) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(3, 5, 22, 23),
          const Radius.circular(2),
        ),
        pen,
      );
      canvas.drawLine(const Offset(3, 12), const Offset(25, 12), pen);
      canvas.drawLine(const Offset(9, 2), const Offset(9, 8), pen);
      canvas.drawLine(const Offset(19, 2), const Offset(19, 8), pen);
      for (final x in [8.0, 14.0, 20.0]) {
        for (final y in [17.0, 23.0]) {
          canvas.drawCircle(Offset(x, y), .75, Paint()..color = color);
        }
      }
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(10, 2)
          ..lineTo(12.5, 9)
          ..lineTo(19, 11)
          ..lineTo(12.5, 13.5)
          ..lineTo(10, 20)
          ..lineTo(7.5, 13.5)
          ..lineTo(1, 11)
          ..lineTo(7.5, 9)
          ..close(),
        pen,
      );
      canvas.drawLine(const Offset(22, 2), const Offset(22, 8), pen);
      canvas.drawLine(const Offset(19, 5), const Offset(25, 5), pen);
      canvas.drawPath(
        Path()
          ..moveTo(15, 18)
          ..lineTo(26, 18)
          ..lineTo(26, 26)
          ..lineTo(20, 26)
          ..lineTo(17, 29)
          ..lineTo(17, 26)
          ..lineTo(15, 26)
          ..close(),
        pen,
      );
      canvas.drawLine(const Offset(18, 21), const Offset(23, 21), pen);
      canvas.drawLine(const Offset(18, 23), const Offset(22, 23), pen);
    }
  }

  @override
  bool shouldRepaint(_ToolIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.coach != coach;
}

Color _muted(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: .68);

TextStyle _type(double size, {Color? color}) =>
    TextStyle(fontSize: size, height: 1.35, letterSpacing: 0, color: color);

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: child);
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: _type(12));
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF090A09) : const Color(0xFFFAFAFA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: dark ? const Color(0xFF292B29) : const Color(0xFFDDDFDD),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _sage.withValues(alpha: .6)),
    ),
    child: Text(
      AppLocalizations.of(context)!.macro_pro_label.toUpperCase(),
      style: _type(
        10,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? _sage
                : const Color(0xFF42694A),
      ),
    ),
  );
}

class _Track extends StatelessWidget {
  const _Track({
    required this.value,
    required this.color,
    this.overflow = false,
  });
  final double value;
  final Color color;
  final bool overflow;
  @override
  Widget build(BuildContext context) => Semantics(
    value: '${(value * 100).round()}%',
    child: SizedBox(
      height: 6,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (overflow)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class HomeMacroSection extends StatelessWidget {
  const HomeMacroSection({
    super.key,
    required this.macros,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
    required this.isPro,
    required this.hasMeals,
    required this.onUpgrade,
  });
  final Macros macros;
  final int proteinGoal, carbGoal, fatGoal;
  final bool isPro, hasMeals;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (!hasMeals) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final rows = [
      (l.result_protein, macros.protein, proteinGoal, 4, _sage),
      (l.result_carbs, macros.carbs, carbGoal, 4, _blue),
      (l.result_fat, macros.fat, fatGoal, 9, _amber),
    ];
    final energy = rows.fold<int>(
      0,
      (sum, r) => sum + math.max(0, r.$2) * r.$4,
    );
    final number = NumberFormat.decimalPattern(l.localeName);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Heading(l.home_section_macros_today),
              if (isPro) ...[const SizedBox(width: 10), const _ProBadge()],
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final expandedText =
                  MediaQuery.textScalerOf(context).scale(13) > 18 ||
                  constraints.maxWidth < 290;
              return Column(
                children:
                    rows.map((r) {
                      final fraction =
                          isPro
                              ? (r.$3 > 0 ? math.max(0, r.$2) / r.$3 : 0.0)
                              : (energy > 0
                                  ? math.max(0, r.$2) * r.$4 / energy
                                  : 0.0);
                      final value =
                          isPro
                              ? '${number.format(r.$2)} / ${r.$3 > 0 ? number.format(r.$3) : "—"}g'
                              : '${number.format((fraction * 100).round())}%';
                      final label = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: r.$5,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: Text(r.$1, style: _type(12))),
                        ],
                      );
                      final track = _Track(
                        value: fraction,
                        color: r.$5,
                        overflow: isPro && fraction > 1,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child:
                            expandedText
                                ? Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: label),
                                        const SizedBox(width: 8),
                                        Text(
                                          value,
                                          textDirection: TextDirection.ltr,
                                          style: _type(12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    track,
                                  ],
                                )
                                : Row(
                                  children: [
                                    SizedBox(width: 84, child: label),
                                    Expanded(child: track),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: isPro ? 96 : 42,
                                      child: Text(
                                        value,
                                        textAlign: TextAlign.end,
                                        textDirection: TextDirection.ltr,
                                        style: _type(13),
                                      ),
                                    ),
                                  ],
                                ),
                      );
                    }).toList(),
              );
            },
          ),
          if (!isPro) ...[
            const SizedBox(height: 8),
            _Surface(
              onTap: onUpgrade,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const _ProBadge(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l.home_dashboard_upgrade, style: _type(11)),
                    ),
                    const SizedBox(width: 8),
                    const _Chevron(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HomeWellnessSection extends StatelessWidget {
  const HomeWellnessSection({
    super.key,
    required this.waterTotal,
    required this.waterGoal,
    required this.steps,
    required this.stepGoal,
    required this.burnedCalories,
    required this.caloriesEstimated,
    required this.onWaterTap,
    required this.onActivityTap,
  });
  final int waterTotal, waterGoal, steps, stepGoal, burnedCalories;
  final bool caloriesEstimated;
  final VoidCallback onWaterTap, onActivityTap;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final number = NumberFormat.decimalPattern(l.localeName);
    final liters = NumberFormat('0.#', l.localeName);
    final water =
        '\u2066${liters.format(waterTotal / 1000)} / ${liters.format(waterGoal / 1000)}\u2069 ${l.home_dashboard_liters}';
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(l.home_daily_wellness),
          const SizedBox(height: 8),
          _Surface(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _WellnessMetric(
                      label: l.water_hydration,
                      value: water,
                      detail: '',
                      icon: const _GlassIcon(),
                      color: const Color(0xFF62829E),
                      progress: waterGoal > 0 ? waterTotal / waterGoal : 0,
                      onTap: onWaterTap,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: .3),
                    ),
                  ),
                  Expanded(
                    child: _WellnessMetric(
                      label: l.home_metric_activity,
                      value:
                          '${number.format(steps)} ${l.log_metric_steps_unit}',
                      detail:
                          caloriesEstimated
                              ? l.home_kcal_estimated_short(burnedCalories)
                              : l.home_kcal_short(burnedCalories),
                      icon: const CustomPaint(
                        size: Size(24, 32),
                        painter: _WalkingPainter(),
                      ),
                      color: _sage,
                      progress: stepGoal > 0 ? steps / stepGoal : 0,
                      onTap: onActivityTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessMetric extends StatelessWidget {
  const _WellnessMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.progress,
    required this.onTap,
  });
  final String label, value, detail;
  final Widget icon;
  final Color color;
  final double progress;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (MediaQuery.textScalerOf(context).scale(11) > 15) ...[
            Align(alignment: AlignmentDirectional.centerStart, child: icon),
            const SizedBox(height: 4),
            Text(label, style: _type(11, color: _muted(context))),
            Text(value, style: _type(15)),
            Text(
              detail.isEmpty ? ' ' : detail,
              style: _type(10, color: _muted(context)),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 24, height: 34, child: Center(child: icon)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: _type(11, color: _muted(context))),
                      Text(value, style: _type(15)),
                      Text(
                        detail.isEmpty ? ' ' : detail,
                        style: _type(10, color: _muted(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const Spacer(),
          const SizedBox(height: 8),
          _Track(value: progress, color: color),
        ],
      ),
    ),
  );
}

class _WalkingPainter extends CustomPainter {
  const _WalkingPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = _sage
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(14, 4), 2.5, Paint()..color = _sage);
    canvas.drawPath(
      Path()
        ..moveTo(13, 10)
        ..lineTo(10, 19)
        ..lineTo(5, 29)
        ..moveTo(10, 19)
        ..lineTo(15, 23)
        ..lineTo(18, 30)
        ..moveTo(12, 11)
        ..lineTo(7, 13)
        ..lineTo(4, 19)
        ..moveTo(13, 11)
        ..lineTo(16, 16)
        ..lineTo(21, 18),
      paint,
    );
  }

  @override
  bool shouldRepaint(_WalkingPainter oldDelegate) => false;
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(22, 32),
    painter: _GlassPainter(_muted(context)),
  );
}

class _GlassPainter extends CustomPainter {
  const _GlassPainter(this.stroke);
  final Color stroke;
  @override
  void paint(Canvas canvas, Size size) {
    final outline =
        Path()
          ..moveTo(2, 2)
          ..lineTo(20, 2)
          ..lineTo(17, 30)
          ..lineTo(5, 30)
          ..close();
    canvas.drawPath(
      Path()
        ..moveTo(5, 20)
        ..lineTo(17, 20)
        ..lineTo(16, 28)
        ..lineTo(6, 28)
        ..close(),
      Paint()..color = const Color(0xFF62829E),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter oldDelegate) => oldDelegate.stroke != stroke;
}

class HomeToolsSection extends StatelessWidget {
  const HomeToolsSection({
    super.key,
    required this.onPlannerTap,
    required this.onCoachTap,
    required this.isPro,
  });
  final VoidCallback onPlannerTap, onCoachTap;
  final bool isPro;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Section(
      child: Column(
        children: [
          _ToolRow(
            title: l.planner_title,
            subtitle: l.home_dashboard_planner,
            action: l.home_dashboard_open,
            icon: _ToolIcon(
              coach: false,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            isPro: isPro,
            onTap: onPlannerTap,
          ),
          const SizedBox(height: 8),
          _ToolRow(
            title: l.assistant_title,
            subtitle: l.home_dashboard_coach,
            action: l.home_dashboard_ask,
            icon: _ToolIcon(
              coach: true,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            isPro: isPro,
            onTap: onCoachTap,
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.icon,
    required this.isPro,
    required this.onTap,
  });
  final String title, subtitle, action;
  final Widget icon;
  final bool isPro;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Surface(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 28, height: 30, child: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _type(13)),
                const SizedBox(height: 2),
                Text(subtitle, style: _type(10, color: _muted(context))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isPro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: .3),
                ),
              ),
              child: Text(action, style: _type(12)),
            )
          else
            const _ProBadge(),
          const SizedBox(width: 8),
          const _Chevron(),
        ],
      ),
    ),
  );
}
