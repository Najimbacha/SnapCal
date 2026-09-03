import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/nutrition/plan_math.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';

import 'widgets/settings_kit.dart';

/// The daily plan: one calorie target and the three macros that make it up.
///
/// The previous version presented four independent numbers and opened with a
/// locked upsell card. It also had no way to show that the macros and the
/// calorie goal disagreed, because the split chart was computed from the
/// macros alone. This screen leads with the plan itself — the shape every
/// tracker its users have already used opens with — and states the
/// relationship between the parts rather than leaving it implied.
class NutritionGoalsScreen extends ConsumerWidget {
  const NutritionGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPro = ref.watch(effectiveIsProProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;

    return AppPageScaffold(
      title: l10n.settings_nutrition_goals_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: settingsBg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlanHero(settings: settings),
          const SizedBox(height: 20),
          _GoalSourceSelector(settings: settings),
          const SizedBox(height: 24),
          _AdjustSection(settings: settings, isPro: isPro),
        ],
      ),
    );
  }
}

/// The plan at a glance: the target, how it sits against maintenance, and the
/// split that makes it up.
class _PlanHero extends StatelessWidget {
  const _PlanHero({required this.settings});

  final UserSettings? settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final calories = settings?.dailyCalorieGoal ?? 2000;
    final split = MacroSplit(
      protein: settings?.dailyProteinGoal ?? 150,
      carbs: settings?.dailyCarbGoal ?? 200,
      fat: settings?.dailyFatGoal ?? 67,
    );
    final shares = split.shares;

    // Only shown where the profile can actually support it. An estimate
    // presented without its inputs is a number pulled from nowhere.
    int? maintenance;
    final weight = settings?.startingWeight;
    final height = settings?.height;
    final age = settings?.age;
    if (weight != null && height != null && age != null) {
      maintenance = estimateMaintenanceCalories(
        weightKg: weight,
        heightCm: height,
        age: age,
        gender: settings?.gender,
        activityLevel: settings?.activityLevel,
      );
    }
    final delta = maintenance == null ? null : calories - maintenance;

    return SettingsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settings_daily_target.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: settingsSubtext(context),
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$calories',
                      style: AppTypography.displayLarge.copyWith(
                        color: settingsText(context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        fontSize: 40,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.settings_kcal_unit,
                      style: AppTypography.bodySmall.copyWith(
                        color: settingsSubtext(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (delta != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      delta > 0 ? '+$delta' : '$delta',
                      style: AppTypography.titleMedium.copyWith(
                        color: kSettingsGreenText,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      l10n.settings_from_maintenance,
                      style: AppTypography.labelSmall.copyWith(
                        color: settingsSubtext(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          _MacroBar(shares: shares),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MacroLegend(
                  color: AppColors.protein,
                  name: l10n.settings_protein,
                  grams: split.protein,
                  kcal: split.protein * kcalPerGramProtein,
                  share: shares.protein,
                ),
              ),
              Expanded(
                child: _MacroLegend(
                  color: AppColors.carbs,
                  name: l10n.settings_carbs,
                  grams: split.carbs,
                  kcal: split.carbs * kcalPerGramCarb,
                  share: shares.carbs,
                ),
              ),
              Expanded(
                child: _MacroLegend(
                  color: AppColors.fat,
                  name: l10n.settings_fat,
                  grams: split.fat,
                  kcal: split.fat * kcalPerGramFat,
                  share: shares.fat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({required this.shares});

  final ({double protein, double carbs, double fat}) shares;

  @override
  Widget build(BuildContext context) {
    // flex takes whole numbers, so shares are scaled rather than rounded to
    // percent — a 0.5% macro still draws as a sliver instead of vanishing.
    return SizedBox(
      height: 10,
      child: Row(
        children: [
          Expanded(
            flex: (shares.protein * 1000).round().clamp(1, 1000),
            child: _Segment(color: AppColors.protein, first: true),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: (shares.carbs * 1000).round().clamp(1, 1000),
            child: _Segment(color: AppColors.carbs),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: (shares.fat * 1000).round().clamp(1, 1000),
            child: _Segment(color: AppColors.fat, last: true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.color, this.first = false, this.last = false});

  final Color color;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(first ? 5 : 2),
          right: Radius.circular(last ? 5 : 2),
        ),
      ),
    );
  }
}

/// Grams, calories and share — the three things people actually ask of a macro
/// target, rather than a gram figure on its own.
class _MacroLegend extends StatelessWidget {
  const _MacroLegend({
    required this.color,
    required this.name,
    required this.grams,
    required this.kcal,
    required this.share,
  });

  final Color color;
  final String name;
  final int grams;
  final int kcal;
  final double share;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: settingsSubtext(context),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '$grams${l10n.settings_grams_unit}',
          style: AppTypography.titleMedium.copyWith(
            color: settingsText(context),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        Text(
          '$kcal ${l10n.settings_kcal_unit} · ${(share * 100).round()}%',
          style: AppTypography.labelSmall.copyWith(
            color: settingsSubtext(context),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

/// Where the targets come from, as a visible mode rather than a question
/// sprung on the user the moment they correct their height.
class _GoalSourceSelector extends ConsumerWidget {
  const _GoalSourceSelector({required this.settings});

  final UserSettings? settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final source = settings?.goalSource ?? kGoalSourceProfile;
    final isProfile = source == kGoalSourceProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSurface(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _SourceTab(
                  label: l10n.settings_goal_source_profile,
                  selected: isProfile,
                  onTap:
                      () => ref
                          .read(settingsProvider.notifier)
                          .setGoalSource(kGoalSourceProfile),
                ),
              ),
              Expanded(
                child: _SourceTab(
                  label: l10n.settings_goal_source_custom,
                  selected: !isProfile,
                  onTap:
                      () => ref
                          .read(settingsProvider.notifier)
                          .setGoalSource(kGoalSourceCustom),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
          child: Text(
            isProfile
                ? l10n.settings_goal_source_note_profile
                : l10n.settings_goal_source_note_custom,
            style: AppTypography.labelSmall.copyWith(
              color: settingsSubtext(context),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceTab extends StatelessWidget {
  const _SourceTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? kSettingsGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  selected
                      ? const Color(0xFFECFDF5)
                      : settingsSubtext(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// The editable rows.
///
/// Free users see their real numbers here. The previous screen showed "Locked"
/// three times while still letting them change calories, which left them with
/// a split they could neither read nor repair — the worst of both. Knowing
/// your macro targets is not the paid feature; changing them is.
class _AdjustSection extends ConsumerWidget {
  const _AdjustSection({required this.settings, required this.isPro});

  final UserSettings? settings;
  final bool isPro;

  void _editMacro(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int current,
    required Future<void> Function(int) onSave,
    required String featureName,
  }) {
    if (!isPro) {
      PremiumConversionService().openPaywall(
        context,
        PaywallEntryPoint.macroDetails,
        featureName: featureName,
      );
      return;
    }
    showSettingsNumberDialog(
      context,
      title: title,
      currentValue: current,
      unit: 'g',
      min: PlanLimits.minMacroGrams,
      max: PlanLimits.maxMacroGrams,
      onSave: (value) async {
        await ref.read(settingsProvider.notifier).claimGoalsAsCustom();
        await onSave(value);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final calories = settings?.dailyCalorieGoal ?? 2000;
    final split = MacroSplit(
      protein: settings?.dailyProteinGoal ?? 150,
      carbs: settings?.dailyCarbGoal ?? 200,
      fat: settings?.dailyFatGoal ?? 67,
    );
    final shares = split.shares;
    final notifier = ref.read(settingsProvider.notifier);

    String pct(double share) =>
        l10n.settings_percent_of_calories('${(share * 100).round()}');

    return SettingsSection(
      title: l10n.settings_group_adjust,
      children: [
        SettingsRow(
          icon: LucideIcons.flame,
          title: l10n.settings_daily_calories,
          value: '$calories ${l10n.settings_kcal_unit}',
          onTap:
              () => showSettingsNumberDialog(
                context,
                title: l10n.settings_daily_calories,
                currentValue: calories,
                unit: 'kcal',
                min: PlanLimits.minCalories,
                max: PlanLimits.maxCalories,
                helperText: l10n.settings_macros_move_note,
                onSave: (value) async {
                  await notifier.claimGoalsAsCustom();
                  await notifier.updateCalorieGoal(value);
                },
              ),
        ),
        SettingsRow(
          icon: LucideIcons.beef,
          title: l10n.settings_protein,
          subtitle: pct(shares.protein),
          value: '${split.protein}${l10n.settings_grams_unit}',
          trailing: isPro ? null : const _ProChip(),
          onTap:
              () => _editMacro(
                context,
                ref,
                title: l10n.settings_protein,
                current: split.protein,
                onSave: notifier.updateProteinGoal,
                featureName: 'settings_protein_goal',
              ),
        ),
        SettingsRow(
          icon: LucideIcons.wheat,
          title: l10n.settings_carbs,
          subtitle: pct(shares.carbs),
          value: '${split.carbs}${l10n.settings_grams_unit}',
          trailing: isPro ? null : const _ProChip(),
          onTap:
              () => _editMacro(
                context,
                ref,
                title: l10n.settings_carbs,
                current: split.carbs,
                onSave: notifier.updateCarbGoal,
                featureName: 'settings_carb_goal',
              ),
        ),
        SettingsRow(
          icon: LucideIcons.droplet,
          title: l10n.settings_fat,
          subtitle: pct(shares.fat),
          value: '${split.fat}${l10n.settings_grams_unit}',
          trailing: isPro ? null : const _ProChip(),
          onTap:
              () => _editMacro(
                context,
                ref,
                title: l10n.settings_fat,
                current: split.fat,
                onSave: notifier.updateFatGoal,
                featureName: 'settings_fat_goal',
              ),
        ),
      ],
    );
  }
}

/// Marks a row as paid without hiding what it says. The number stays readable;
/// the chip says who may change it.
class _ProChip extends StatelessWidget {
  const _ProChip();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kSettingsGreenText.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        l10n.macro_pro_label.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: kSettingsGreenText,
          fontWeight: FontWeight.w800,
          fontSize: 9.5,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
