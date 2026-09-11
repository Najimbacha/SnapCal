import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../core/theme/app_typography.dart';
import '../../providers/auth_state_provider.dart';
import '../../core/nutrition/plan_math.dart';
import '../../providers/settings_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../data/models/user_settings.dart';
import '../../widgets/app_page_scaffold.dart';
import 'widgets/weight_entry_modal.dart';

import 'widgets/settings_kit.dart';

class BodyProfileScreen extends ConsumerWidget {
  const BodyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageScaffold(
      title: l10n.settings_body_profile_title,
      subtitle: l10n.settings_body_profile_desc,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      backgroundColor: settingsBg(context),
      child: Column(
        children: [
          const _WeightProgressBar(),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.settings_group_about_you,
            children: [
              SettingsRow(
                icon: LucideIcons.user,
                title: l10n.settings_display_name_label,
                value:
                    ref.watch(authStateProvider).valueOrNull?.displayName ??
                    l10n.settings_set_name,
                onTap:
                    () => showSettingsNameDialog(
                      context,
                      ref,
                      ref.watch(authStateProvider).valueOrNull?.displayName ??
                          '',
                    ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(settingsProvider).valueOrNull;
                  return Column(
                    children: [
                      SettingsRow(
                        icon: LucideIcons.calendar,
                        title: l10n.settings_age,
                        value: settings?.age?.toString() ?? '--',
                        onTap:
                            () => showSettingsNumberDialog(
                              context,
                              title: l10n.settings_age,
                              currentValue: settings?.age ?? 25,
                              unit: 'yrs',
                              min: PlanLimits.minAge,
                              max: PlanLimits.maxAge,
                              onSave: (value) async {
                                final notifier = ref.read(
                                  settingsProvider.notifier,
                                );
                                final weight =
                                    ref
                                        .read(bodyMetricsProvider.notifier)
                                        .currentWeight;
                                await notifier.updateBodyProfile(
                                  age: value,
                                  currentWeightKg: weight,
                                );
                              },
                            ),
                      ),
                      SettingsRow(
                        icon: LucideIcons.userCircle,
                        title: l10n.settings_sex,
                        subtitle: l10n.settings_sex_hint,
                        value:
                            settings?.gender != null
                                ? localizeGender(context, settings!.gender!)
                                : '--',
                        onTap:
                            () => showGenderSelector(
                              context,
                              ref,
                              settings ?? UserSettings.defaults(),
                            ),
                      ),
                    ],
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(settingsProvider).valueOrNull;
                  final height = settings?.height;
                  // Imperial heights are edited in inches. The units picker
                  // used to save "ft", which this screen then read as
                  // centimetres: "170 FT", and edits were saved as cm.
                  final imperial = isImperialHeight(settings?.heightUnit);
                  final inches =
                      height == null ? null : (height / 2.54).round();
                  final String shown;
                  if (height == null) {
                    shown = l10n.settings_set_height;
                  } else if (inches != null && imperial) {
                    shown = '${inches ~/ 12}′ ${inches % 12}″';
                  } else {
                    shown = '${height.round()} ${localizeUnit(context, 'cm')}';
                  }
                  return SettingsRow(
                    icon: LucideIcons.ruler,
                    title: l10n.settings_height,
                    value: shown,
                    onTap:
                        () => showSettingsNumberDialog(
                          context,
                          title: l10n.settings_height,
                          currentValue:
                              (imperial ? inches : height?.round()) ??
                              (imperial ? 67 : 170),
                          unit: imperial ? 'in' : 'cm',
                          min:
                              imperial
                                  ? (PlanLimits.minHeightCm / 2.54).round()
                                  : PlanLimits.minHeightCm.round(),
                          max:
                              imperial
                                  ? (PlanLimits.maxHeightCm / 2.54).round()
                                  : PlanLimits.maxHeightCm.round(),
                          onSave: (value) async {
                            final cm =
                                imperial ? value * 2.54 : value.toDouble();
                            final notifier = ref.read(
                              settingsProvider.notifier,
                            );
                            final weight =
                                ref
                                    .read(bodyMetricsProvider.notifier)
                                    .currentWeight;
                            await notifier.updateBodyProfile(
                              height: cm,
                              currentWeightKg: weight,
                            );
                          },
                        ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.settings_group_weight,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final weightUnit =
                      ref.watch(settingsProvider).valueOrNull?.weightUnit ??
                      'kg';
                  final metrics =
                      ref.watch(bodyMetricsProvider).valueOrNull ?? [];
                  final currentWeight =
                      metrics.isEmpty ? null : metrics.first.weight;
                  double? displayWeight = currentWeight;
                  if (displayWeight != null && weightUnit == 'lb') {
                    displayWeight = displayWeight * 2.20462;
                  }
                  return SettingsRow(
                    icon: LucideIcons.scale,
                    title: l10n.settings_current_weight,
                    value:
                        displayWeight != null
                            ? '${displayWeight.toStringAsFixed(1)} ${localizeUnit(context, weightUnit)}'
                            : l10n.settings_set_weight,
                    onTap:
                        () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const WeightEntryModal(),
                        ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final targetWeight =
                      ref.watch(settingsProvider).valueOrNull?.targetWeight;
                  final weightUnit =
                      ref.watch(settingsProvider).valueOrNull?.weightUnit ??
                      'kg';
                  double? displayTarget = targetWeight;
                  if (displayTarget != null && weightUnit == 'lb') {
                    displayTarget = displayTarget * 2.20462;
                  }
                  return SettingsRow(
                    icon: LucideIcons.target,
                    title: l10n.settings_target_weight,
                    value:
                        displayTarget != null
                            ? '${displayTarget.toStringAsFixed(1)} ${localizeUnit(context, weightUnit)}'
                            : l10n.settings_set_target,
                    onTap:
                        () => showSettingsDecimalDialog(
                          context,
                          title: l10n.settings_target_weight,
                          currentValue:
                              displayTarget ?? (weightUnit == 'lb' ? 154 : 70),
                          unit: weightUnit,
                          min:
                              weightUnit == 'lb'
                                  ? PlanLimits.minWeightKg * 2.20462
                                  : PlanLimits.minWeightKg,
                          max:
                              weightUnit == 'lb'
                                  ? PlanLimits.maxWeightKg * 2.20462
                                  : PlanLimits.maxWeightKg,
                          onSave: (value) async {
                            double kg = value;
                            if (weightUnit == 'lb') kg = value / 2.20462;
                            final notifier = ref.read(
                              settingsProvider.notifier,
                            );
                            final weight =
                                ref
                                    .read(bodyMetricsProvider.notifier)
                                    .currentWeight;
                            await notifier.updateBodyProfile(
                              targetWeight: kg,
                              currentWeightKg: weight,
                            );
                          },
                        ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: l10n.settings_units, // "Units"
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(settingsProvider).valueOrNull;
                  return SettingsRow(
                    icon: LucideIcons.settings,
                    title: l10n.settings_units,
                    value:
                        '${localizeUnit(context, settings?.weightUnit ?? 'kg').toUpperCase()} / ${localizeUnit(context, settings?.heightUnit ?? 'cm').toUpperCase()}',
                    onTap:
                        () => showUnitSelector(
                          context,
                          settings ?? UserSettings.defaults(),
                          ref,
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

class _WeightProgressBar extends StatelessWidget {
  const _WeightProgressBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsProvider).valueOrNull;
        final unit = settings?.weightUnit ?? 'kg';
        final startWeightKg = settings?.startingWeight;
        // Watched, so a new weigh-in moves the bar. Read alone, it waited
        // for the next settings change.
        ref.watch(bodyMetricsProvider);
        final currentWeightKg =
            ref.read(bodyMetricsProvider.notifier).currentWeight ??
            startWeightKg;
        final targetWeightKg = settings?.targetWeight;

        if (startWeightKg == null ||
            targetWeightKg == null ||
            currentWeightKg == null) {
          return const SizedBox.shrink();
        }

        // Convert weights for display
        final double startWeight =
            unit == 'lb' ? startWeightKg * 2.20462 : startWeightKg;
        final double currentWeight =
            unit == 'lb' ? currentWeightKg * 2.20462 : currentWeightKg;
        final double targetWeight =
            unit == 'lb' ? targetWeightKg * 2.20462 : targetWeightKg;

        // Calculate progress percentage
        double progress = 0.0;
        final diffTotal = (startWeight - targetWeight).abs();
        if (diffTotal > 0.01) {
          if (targetWeight < startWeight) {
            // Weight loss goal
            progress =
                (startWeight - currentWeight) / (startWeight - targetWeight);
          } else {
            // Weight gain goal
            progress =
                (currentWeight - startWeight) / (targetWeight - startWeight);
          }
          progress = progress.clamp(0.0, 1.0);
        }

        final isLoss = targetWeight < startWeight;
        final leftToGoal = weightLeftToGoal(
          start: startWeight,
          current: currentWeight,
          target: targetWeight,
        );

        final l10n = AppLocalizations.of(context)!;
        return SettingsSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isLoss
                        ? l10n.settings_weight_loss_progress
                        : l10n.settings_weight_gain_progress,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: settingsText(context),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: kSettingsGreenText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Container(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : kSettingsLine,
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(color: kSettingsGreenText),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Values legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _WeightLabel(
                    label: l10n.settings_weight_start,
                    value:
                        '${startWeight.toStringAsFixed(1)} ${localizeUnit(context, unit)}',
                    alignment: CrossAxisAlignment.start,
                  ),
                  _WeightLabel(
                    label: l10n.settings_weight_current,
                    value:
                        '${currentWeight.toStringAsFixed(1)} ${localizeUnit(context, unit)}',
                    isHighlight: true,
                    alignment: CrossAxisAlignment.center,
                  ),
                  _WeightLabel(
                    label: l10n.settings_weight_target,
                    value:
                        '${targetWeight.toStringAsFixed(1)} ${localizeUnit(context, unit)}',
                    alignment: CrossAxisAlignment.end,
                  ),
                ],
              ),
              if (diffTotal > 0.01) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : kSettingsLine,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    leftToGoal <= 0.1
                        ? l10n.settings_goal_reached
                        : l10n.settings_left_to_reach_target(
                          leftToGoal.toStringAsFixed(1),
                          localizeUnit(context, unit),
                        ),
                    style: AppTypography.labelSmall.copyWith(
                      color: settingsSubtext(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WeightLabel extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final CrossAxisAlignment alignment;

  const _WeightLabel({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: isHighlight ? kSettingsGreenText : settingsSubtext(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
            color:
                isHighlight ? settingsText(context) : settingsSubtext(context),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
