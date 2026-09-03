import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/nutrition/plan_math.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';

import 'widgets/settings_kit.dart';

class NutritionGoalsScreen extends ConsumerWidget {
  const NutritionGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPro = ref.watch(effectiveIsProProvider);
    return AppPageScaffold(
      title: l10n.settings_nutrition_goals_title,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: settingsBg(context),
      child: Column(
        children: [
          if (isPro)
            const _MacroCalorieRelationshipCard()
          else
            _LockedMacroGoalsCard(
              onTap:
                  () => PremiumConversionService().openPaywall(
                    context,
                    PaywallEntryPoint.macroDetails,
                    featureName: 'settings_macro_split',
                  ),
            ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.settings_nutrition_goals, // "Nutrition Goals"
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(settingsProvider).valueOrNull;
                  final value = settings?.dailyCalorieGoal ?? 2000;

                  // A calorie target means little on its own. Where the
                  // profile is complete enough to estimate it, show roughly
                  // what the user burns so the number they type has something
                  // to be relative to. Absent that, fall back to explaining
                  // what changing it will do.
                  String? maintenanceHint;
                  final weight = settings?.startingWeight;
                  final height = settings?.height;
                  final age = settings?.age;
                  if (weight != null && height != null && age != null) {
                    final maintenance = estimateMaintenanceCalories(
                      weightKg: weight,
                      heightCm: height,
                      age: age,
                      gender: settings?.gender,
                      activityLevel: settings?.activityLevel,
                    );
                    maintenanceHint = l10n.settings_maintenance_estimate(
                      '$maintenance',
                    );
                  }

                  return SettingsRow(
                    icon: LucideIcons.flame,
                    title: l10n.settings_daily_calories,
                    value: '$value ${l10n.settings_kcal_unit}',
                    onTap:
                        () => showSettingsNumberDialog(
                          context,
                          title: l10n.settings_daily_calories,
                          currentValue: value,
                          unit: 'kcal',
                          min: PlanLimits.minCalories,
                          max: PlanLimits.maxCalories,
                          helperText:
                              maintenanceHint ??
                              l10n.settings_calories_adjust_macros_note,
                          onSave:
                              ref
                                  .read(settingsProvider.notifier)
                                  .updateCalorieGoal,
                        ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final value =
                      ref
                          .watch(settingsProvider)
                          .valueOrNull
                          ?.dailyProteinGoal ??
                      50;
                  return SettingsRow(
                    icon: LucideIcons.beef,
                    title: l10n.settings_protein,
                    value:
                        isPro
                            ? '$value${l10n.settings_grams_unit}'
                            : l10n.macro_locked_placeholder,
                    onTap:
                        isPro
                            ? () => showSettingsNumberDialog(
                              context,
                              title: l10n.settings_protein,
                              currentValue: value,
                              unit: 'g',
                              min: PlanLimits.minMacroGrams,
                              max: PlanLimits.maxMacroGrams,
                              onSave:
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateProteinGoal,
                            )
                            : () => PremiumConversionService().openPaywall(
                              context,
                              PaywallEntryPoint.macroDetails,
                              featureName: 'settings_protein_goal',
                            ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final value =
                      ref.watch(settingsProvider).valueOrNull?.dailyCarbGoal ??
                      250;
                  return SettingsRow(
                    icon: LucideIcons.wheat,
                    title: l10n.settings_carbs,
                    value:
                        isPro
                            ? '$value${l10n.settings_grams_unit}'
                            : l10n.macro_locked_placeholder,
                    onTap:
                        isPro
                            ? () => showSettingsNumberDialog(
                              context,
                              title: l10n.settings_carbs,
                              currentValue: value,
                              unit: 'g',
                              min: PlanLimits.minMacroGrams,
                              max: PlanLimits.maxMacroGrams,
                              onSave:
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateCarbGoal,
                            )
                            : () => PremiumConversionService().openPaywall(
                              context,
                              PaywallEntryPoint.macroDetails,
                              featureName: 'settings_carb_goal',
                            ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final value =
                      ref.watch(settingsProvider).valueOrNull?.dailyFatGoal ??
                      65;
                  return SettingsRow(
                    icon: LucideIcons.droplets,
                    title: l10n.settings_fat,
                    value:
                        isPro
                            ? '$value${l10n.settings_grams_unit}'
                            : l10n.macro_locked_placeholder,
                    onTap:
                        isPro
                            ? () => showSettingsNumberDialog(
                              context,
                              title: l10n.settings_fat,
                              currentValue: value,
                              unit: 'g',
                              min: PlanLimits.minMacroGrams,
                              max: PlanLimits.maxMacroGrams,
                              onSave:
                                  ref
                                      .read(settingsProvider.notifier)
                                      .updateFatGoal,
                            )
                            : () => PremiumConversionService().openPaywall(
                              context,
                              PaywallEntryPoint.macroDetails,
                              featureName: 'settings_fat_goal',
                            ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCalorieRelationshipCard extends StatelessWidget {
  const _MacroCalorieRelationshipCard();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final settings = ref.watch(settingsProvider).valueOrNull;
        final pGrams = settings?.dailyProteinGoal ?? 50;
        final cGrams = settings?.dailyCarbGoal ?? 250;
        final fGrams = settings?.dailyFatGoal ?? 65;
        final calorieGoal = settings?.dailyCalorieGoal ?? 2000;

        final split = MacroSplit(protein: pGrams, carbs: cGrams, fat: fGrams);
        final shares = split.shares;

        // Per-macro energy, for the legend. Taken from the shared constants so
        // the card and the plan maths can never drift apart on 4/4/9.
        final pKcal = (pGrams * kcalPerGramProtein).toDouble();
        final cKcal = (cGrams * kcalPerGramCarb).toDouble();
        final fKcal = (fGrams * kcalPerGramFat).toDouble();
        final pPct = shares.protein;
        final cPct = shares.carbs;
        final fPct = shares.fat;

        // This card used to compute its percentages from the macros alone, so
        // it could never show that they disagreed with the calorie goal
        // printed two rows below it — it drew a confident, tidy bar over a
        // contradiction. It now states the relationship it is named after.
        final agrees = macrosAgreeWithCalories(split, calorieGoal);
        final drift = macroCalorieDrift(split, calorieGoal);

        final l10n = AppLocalizations.of(context)!;
        return SettingsSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settings_macro_calorie_split,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: settingsText(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.settings_macro_calorie_split_desc,
                style: AppTypography.labelSmall.copyWith(
                  color: settingsSubtext(context),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    agrees ? LucideIcons.check : LucideIcons.alertTriangle,
                    size: 14,
                    color:
                        agrees ? kSettingsGreenText : const Color(0xFFE0A34F),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      agrees
                          ? l10n.settings_macros_match_goal
                          : (drift > 0
                              ? l10n.settings_macros_over_goal('$drift')
                              : l10n.settings_macros_under_goal(
                                '${drift.abs()}',
                              )),
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            agrees
                                ? settingsSubtext(context)
                                : const Color(0xFFE0A34F),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Segmented bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      if (pPct > 0)
                        Expanded(
                          flex: (pPct * 1000).round(),
                          child: Container(color: kSettingsGreenText),
                        ),
                      if (cPct > 0)
                        Expanded(
                          flex: (cPct * 1000).round(),
                          child: Container(
                            color: kSettingsGreenText.withValues(alpha: 0.58),
                          ),
                        ),
                      if (fPct > 0)
                        Expanded(
                          flex: (fPct * 1000).round(),
                          child: Container(
                            color: kSettingsGreenText.withValues(alpha: 0.32),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MacroLegendItem(
                    label: l10n.settings_protein,
                    grams: '$pGrams${l10n.settings_grams_unit}',
                    kcal: '${pKcal.round()} ${l10n.settings_kcal_unit}',
                    percentage: '${(pPct * 100).round()}%',
                    color: kSettingsGreenText,
                  ),
                  _MacroLegendItem(
                    label: l10n.settings_carbs,
                    grams: '$cGrams${l10n.settings_grams_unit}',
                    kcal: '${cKcal.round()} ${l10n.settings_kcal_unit}',
                    percentage: '${(cPct * 100).round()}%',
                    color: kSettingsGreenText.withValues(alpha: 0.58),
                  ),
                  _MacroLegendItem(
                    label: l10n.settings_fat,
                    grams: '$fGrams${l10n.settings_grams_unit}',
                    kcal: '${fKcal.round()} ${l10n.settings_kcal_unit}',
                    percentage: '${(fPct * 100).round()}%',
                    color: kSettingsGreenText.withValues(alpha: 0.32),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LockedMacroGoalsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LockedMacroGoalsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaleTap(
      onTap: onTap,
      child: SettingsSurface(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kSettingsGreenText.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.lock,
                color: kSettingsGreenText,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.macro_locked_title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: settingsText(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.macro_locked_body,
                    style: AppTypography.labelSmall.copyWith(
                      color: settingsSubtext(context),
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              LucideIcons.chevronRight,
              color: settingsSubtext(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroLegendItem extends StatelessWidget {
  final String label;
  final String grams;
  final String kcal;
  final String percentage;
  final Color color;

  const _MacroLegendItem({
    required this.label,
    required this.grams,
    required this.kcal,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: settingsSubtext(context),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          grams,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: settingsText(context),
            fontSize: 14,
          ),
        ),
        Text(
          '$kcal ($percentage)',
          style: AppTypography.labelSmall.copyWith(
            color: settingsSubtext(context),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
