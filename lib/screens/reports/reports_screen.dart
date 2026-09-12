import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/body_metric.dart';
import '../../data/models/meal.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../data/services/pro_feature_service.dart';
import '../../data/services/report_pdf_service.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/premium_prompt_card.dart';
import '../../widgets/ui_blocks.dart';
import '../settings/widgets/weight_entry_modal.dart';
import 'stats_data.dart';

/// What the user's own numbers say about the last week or month.
///
/// This screen used to open two tabs of charts behind a period picker hidden
/// in a corner menu, and threw a paywall over the top two seconds after
/// arrival. It now answers the question people come here with -- am I eating
/// what I meant to? -- in a sentence, and shows the working underneath.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _days = 7;
  bool _isExporting = false;

  Future<void> _exportPdfReport() async {
    if (_isExporting) return;

    // ref.read, not ref.watch: this runs from a button callback, and watching
    // outside build registers a dependency that leaks and rebuilds the screen.
    final settingsVal = ref.read(settingsProvider).valueOrNull;
    final access = ref.read(proAccessProvider);
    if (access.isUnknown) return;
    if (!access.can(ProFeature.reports)) {
      PremiumConversionService().openPaywall(
        context,
        PaywallEntryPoint.reportInsight,
        featureName: 'pdf_export',
      );
      return;
    }

    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      final authState = ref.read(authStateProvider).valueOrNull;
      final userName =
          authState?.displayName ??
          authState?.email?.split('@').first ??
          AppLocalizations.of(context)!.report_guest_user;
      final repo = await ref.read(mealRepositoryProvider.future);

      await ReportPdfService.generateAndShareReport(
        userName: userName,
        meals: repo.getAllMeals(),
        settings: settingsVal ?? UserSettings.defaults(),
        streak: settingsVal?.currentStreak ?? 0,
      );
    } catch (e) {
      // The raw exception meant nothing to the user; it belongs in the log.
      debugPrint('PDF report failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.report_failed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _pickRange(int days, bool isPro) {
    if (days == _days) return;
    if (days > 7 && !isPro) {
      HapticFeedback.mediumImpact();
      PremiumConversionService().openPaywall(
        context,
        PaywallEntryPoint.reportInsight,
        featureName: 'stats_30_days',
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _days = days);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsProvider);
    final repoAsync = ref.watch(mealRepositoryProvider);
    // Rebuilt when today's meals change, and when the day itself does.
    ref.watch(todaysMealsProvider);
    final isPro = ref.watch(effectiveIsProProvider);

    return AppPageScaffold(
      title: l10n.report_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
      trailing: _ExportButton(
        busy: _isExporting,
        onTap: _exportPdfReport,
        tooltip: l10n.stats_export,
      ),
      child:
          settingsAsync.isLoading || repoAsync.isLoading
              ? const Padding(
                padding: EdgeInsets.only(top: 16),
                child: AppSectionSkeleton(rows: 4),
              )
              : _body(
                context,
                l10n,
                settingsAsync.valueOrNull ?? UserSettings.defaults(),
                repoAsync.valueOrNull,
                isPro,
              ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    UserSettings settings,
    MealRepository? repo,
    bool isPro,
  ) {
    final today = DateTime.now();
    final summary = NutritionReportSummary.compute(
      days: _days,
      today: today,
      mealsForDate: (date) => repo?.getMealsByDate(date) ?? const <Meal>[],
    );
    final target = settings.dailyCalorieGoal;
    final metrics = ref.watch(bodyMetricsProvider).valueOrNull;
    final trend =
        metrics == null
            ? null
            : WeightTrend.from(all: metrics, days: _days, today: today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        _RangeToggle(
          days: _days,
          isPro: isPro,
          onPick: (days) => _pickRange(days, isPro),
        ),
        const SizedBox(height: 18),
        if (!summary.hasData)
          AppEmptyState(
            icon: LucideIcons.barChart2,
            title: l10n.stats_no_data_title,
            body: l10n.stats_no_data_body,
          )
        else ...[
          _HeadlineCard(summary: summary, target: target),
          const SizedBox(height: 18),
          SectionLabel(title: l10n.report_calorie_trend),
          const SizedBox(height: 10),
          _CalorieChart(summary: summary, target: target, today: today),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: l10n.stats_days_logged_label,
                  value: '${summary.loggedDays}/${summary.days}',
                  hint: '${summary.consistencyPercent}%',
                  accent: AppColors.primary,
                  icon: LucideIcons.calendarCheck,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  label: l10n.stats_streak_label,
                  value: '${settings.currentStreak}',
                  hint: l10n.stats_streak_days(settings.currentStreak),
                  accent: AppColors.warning,
                  icon: LucideIcons.flame,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionLabel(title: l10n.stats_macros_title),
          const SizedBox(height: 10),
          _MacroBars(summary: summary, settings: settings),
        ],
        const SizedBox(height: 18),
        SectionLabel(title: l10n.stats_weight_title),
        const SizedBox(height: 10),
        _WeightCard(trend: trend, settings: settings, days: _days),
        if (!isPro) ...[
          const SizedBox(height: 22),
          PremiumPromptCard(
            icon: LucideIcons.lineChart,
            title: l10n.stats_pro_title,
            subtitle: l10n.stats_pro_subtitle,
            buttonText: l10n.stats_pro_button,
            onTap:
                () => PremiumConversionService().openPaywall(
                  context,
                  PaywallEntryPoint.reportInsight,
                  featureName: 'stats_screen',
                ),
          ),
        ],
      ],
    );
  }
}

/// 7 days or 30, in the open, where a period picker belongs.
class _RangeToggle extends StatelessWidget {
  const _RangeToggle({
    required this.days,
    required this.isPro,
    required this.onPick,
  });

  final int days;
  final bool isPro;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RangeOption(
              label: l10n.stats_range_7,
              selected: days == 7,
              onTap: () => onPick(7),
            ),
          ),
          Expanded(
            child: _RangeOption(
              label: l10n.stats_range_30,
              selected: days == 30,
              // Free users see the lock rather than a button that silently
              // does nothing.
              locked: !isPro,
              onTap: () => onPick(30),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeOption extends StatelessWidget {
  const _RangeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locked) ...[
              Icon(LucideIcons.lock, size: 12, color: context.textMutedColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color:
                      selected
                          ? Colors.white
                          : locked
                          ? context.textMutedColor
                          : context.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The answer, in words and one big number.
class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.summary, required this.target});

  final NutritionReportSummary summary;
  final int target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final gap = summary.gapTo(target);
    final onTarget = summary.onTarget(target);
    final over = gap > 0;

    final (verdict, accent) = switch ((target <= 0, onTarget, over)) {
      (true, _, _) => ('', AppColors.primary),
      (_, true, _) => (l10n.stats_on_target, AppColors.primary),
      (_, _, true) => (l10n.stats_over_target(gap), AppColors.warning),
      _ => (l10n.stats_under_target(-gap), AppColors.primary),
    };

    return AppSectionCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                number.format(summary.avgCalories),
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: context.textPrimaryColor,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'kcal',
                  style: AppTypography.labelLarge.copyWith(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.stats_avg_per_day,
            style: AppTypography.bodySmall.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          if (verdict.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    onTarget
                        ? LucideIcons.check
                        : over
                        ? LucideIcons.trendingUp
                        : LucideIcons.trendingDown,
                    size: 14,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      verdict,
                      maxLines: 2,
                      style: AppTypography.labelMedium.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.stats_logged_days(summary.loggedDays, summary.days),
            style: AppTypography.bodySmall.copyWith(
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Calories per day with the target drawn across them, so an over-day is a
/// bar poking above a line rather than a number to work out.
class _CalorieChart extends StatefulWidget {
  const _CalorieChart({
    required this.summary,
    required this.target,
    required this.today,
  });

  final NutritionReportSummary summary;
  final int target;
  final DateTime today;

  @override
  State<_CalorieChart> createState() => _CalorieChartState();
}

class _CalorieChartState extends State<_CalorieChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final days = widget.summary.dailyCalories;
    // The line has to sit inside the chart even on a week that stayed under
    // it, so the scale takes in the target as well as the highest day.
    final ceiling =
        [
          widget.summary.peakCalories,
          widget.target,
          1,
        ].reduce((a, b) => a > b ? a : b) *
        1.15;
    final selected = _selected;
    final dayFormat = DateFormat.MMMd(l10n.localeName);
    // A month of bars cannot carry a label each; a week can.
    final labelEvery = days.length > 14 ? 7 : 1;

    return AppSectionCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 2,
                decoration: BoxDecoration(
                  color: context.textMutedColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${l10n.stats_target_line} ${number.format(widget.target)}',
                style: AppTypography.labelSmall.copyWith(
                  color: context.textMutedColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  selected == null
                      ? l10n.stats_chart_hint
                      : '${dayFormat.format(_dateFor(selected))} · ${number.format(days[selected])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTypography.labelSmall.copyWith(
                    color:
                        selected == null
                            ? context.textMutedColor
                            : AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 132,
            child: Stack(
              children: [
                // The target line, behind the bars.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 22 + (widget.target / ceiling) * 110,
                  child: _DashedLine(color: context.dividerColor),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < days.length; i++)
                      Expanded(
                        child: _Bar(
                          kcal: days[i],
                          height: (days[i] / ceiling) * 110,
                          over: widget.target > 0 && days[i] > widget.target,
                          selected: selected == i,
                          narrow: days.length > 14,
                          label:
                              i % labelEvery == 0
                                  ? DateFormat(
                                    days.length > 14 ? 'd' : 'E',
                                    l10n.localeName,
                                  ).format(_dateFor(i))
                                  : '',
                          onTap:
                              () => setState(
                                () => _selected = selected == i ? null : i,
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime _dateFor(int index) {
    final offset = widget.summary.days - 1 - index;
    return DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day - offset,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.kcal,
    required this.height,
    required this.over,
    required this.selected,
    required this.narrow,
    required this.label,
    required this.onTap,
  });

  final int kcal;
  final double height;
  final bool over;
  final bool selected;
  final bool narrow;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = kcal <= 0;
    final color =
        empty
            ? context.dividerColor.withValues(alpha: 0.6)
            : over
            ? AppColors.warning
            : AppColors.primary;

    return GestureDetector(
      onTap: empty ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(horizontal: narrow ? 1 : 4),
            height: empty ? 3 : height.clamp(4, 110),
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 1 : 0.85),
              borderRadius: BorderRadius.circular(narrow ? 3 : 6),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 14,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                color: selected ? AppColors.primary : context.textMutedColor,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const dash = 5.0;
      final count = (constraints.maxWidth / (dash * 2)).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          count.clamp(1, 60),
          (_) => Container(width: dash, height: 1.4, color: color),
        ),
      );
    },
  );
}

/// Average protein, carbs and fat against their targets.
///
/// A pie chart said protein was a quarter of something; a bar against the
/// target says whether the day's protein was met.
class _MacroBars extends StatelessWidget {
  const _MacroBars({required this.summary, required this.settings});

  final NutritionReportSummary summary;
  final UserSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = [
      (
        l10n.report_macro_protein,
        summary.avgProtein,
        settings.dailyProteinGoal,
        AppColors.protein,
      ),
      (
        l10n.report_macro_carbs,
        summary.avgCarbs,
        settings.dailyCarbGoal,
        AppColors.carbs,
      ),
      (
        l10n.report_macro_fat,
        summary.avgFat,
        settings.dailyFatGoal,
        AppColors.fat,
      ),
    ];

    return AppSectionCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        children: [
          for (final (label, value, goal, color) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MacroBar(
                label: label,
                value: value,
                goal: goal,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  final String label;
  final int value;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final share = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                l10n.stats_macro_of_target(value, goal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTypography.labelSmall.copyWith(
                  color: context.textMutedColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(
                height: 8,
                color: context.dividerColor.withValues(alpha: 0.5),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                widthFactor: share,
                child: Container(height: 8, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Weight over the period, or a way to start recording it.
class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.trend,
    required this.settings,
    required this.days,
  });

  final WeightTrend? trend;
  final UserSettings settings;
  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imperial = settings.weightUnit == 'lb';
    final unitLabel = imperial ? 'lb' : 'kg';
    double convert(double kg) => imperial ? kg * 2.20462 : kg;

    void logWeight() => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WeightEntryModal(),
    );

    final current = trend;
    if (current == null) {
      return AppSectionCard(
        child: AppEmptyState(
          icon: LucideIcons.scale,
          title: l10n.report_no_weight_title,
          body: l10n.report_no_weight_body,
          actionLabel: l10n.report_log_weight,
          onAction: logWeight,
        ),
      );
    }

    final change = convert(current.changeKg);
    final gained = change > 0;
    final flat = change.abs() < 0.05;

    return AppSectionCard(
      padding: const EdgeInsets.all(22),
      onTap: logWeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                convert(current.latestKg).toStringAsFixed(1),
                style: AppTypography.heading1.copyWith(
                  fontWeight: FontWeight.w900,
                  color: context.textPrimaryColor,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unitLabel,
                  style: AppTypography.labelLarge.copyWith(
                    color: context.textMutedColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              if (current.hasTrend)
                Row(
                  children: [
                    Icon(
                      flat
                          ? LucideIcons.minus
                          : gained
                          ? LucideIcons.arrowUpRight
                          : LucideIcons.arrowDownRight,
                      size: 15,
                      color: flat ? context.textMutedColor : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change.abs().toStringAsFixed(1)} $unitLabel',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color:
                            flat ? context.textMutedColor : AppColors.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            current.hasTrend
                ? l10n.stats_weight_since(days)
                : l10n.stats_weight_one_entry,
            style: AppTypography.bodySmall.copyWith(
              color: context.textMutedColor,
            ),
          ),
          if (current.hasTrend) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: _WeightSparkline(entries: current.entries),
            ),
          ],
        ],
      ),
    );
  }
}

/// The shape of the weigh-ins, without axes or gridlines: at this size the
/// direction is the only readable thing, so it is the only thing drawn.
class _WeightSparkline extends StatelessWidget {
  const _WeightSparkline({required this.entries});

  final List<BodyMetric> entries;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SparklinePainter(
      values: entries.map((e) => e.weight).toList(),
      color: AppColors.primary,
    ),
    child: const SizedBox.expand(),
  );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lowest = values.reduce((a, b) => a < b ? a : b);
    final highest = values.reduce((a, b) => a > b ? a : b);
    // A flat run would divide by zero and a near-flat one would draw a cliff,
    // so a minimum span keeps small changes looking small.
    final span = (highest - lowest) < 0.5 ? 0.5 : highest - lowest;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height * (1 - (values[i] - lowest) / span);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // A dot on the latest weigh-in, so the end of the line reads as now.
    canvas.drawCircle(
      Offset(size.width, size.height * (1 - (values.last - lowest) / span)),
      3.5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.busy,
    required this.onTap,
    required this.tooltip,
  });

  final bool busy;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: AppScaleTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child:
              busy
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Icon(
                    LucideIcons.share,
                    size: 20,
                    color: colorScheme.primary,
                  ),
        ),
      ),
    );
  }
}
