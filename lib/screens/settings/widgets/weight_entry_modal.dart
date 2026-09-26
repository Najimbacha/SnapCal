import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../core/theme/app_motion.dart';
import '../../../widgets/motion/reveal.dart';
import '../../../widgets/wazn_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/nutrition/plan_math.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/body_metric.dart';
import '../../../providers/metrics_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/ui_blocks.dart';
import 'settings_kit.dart';

const _settingsBgLight = Color(0xFFF9F8F5);
const _settingsBgDark = Color(0xFF14130F);
const _settingsInk = Color(0xFF1C1917);
const _settingsLine = Color(0xFFE8E4DC);
const _settingsGreen = Color(0xFF1A3D2B);
const _settingsGreenText = Color(0xFF16733A);

Color _settingsBg(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? _settingsBgDark
      : _settingsBgLight;
}

Color _settingsText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : _settingsInk;
}

class WeightEntryModal extends ConsumerStatefulWidget {
  const WeightEntryModal({super.key});

  @override
  ConsumerState<WeightEntryModal> createState() => _WeightEntryModalState();
}

class _WeightEntryModalState extends ConsumerState<WeightEntryModal>
    with TickerProviderStateMixin {
  static const _minBodyFat = 3;
  static const _maxBodyFat = 70;

  late final TextEditingController _weightController;
  String? _error;
  late final TextEditingController _bodyFatController;

  /// A small shake of the box when the number will not do.
  late final AnimationController _shake;

  /// The tick on Save, shown before the sheet goes.
  late final AnimationController _saved;

  @override
  void initState() {
    super.initState();
    final metricsList =
        ref.read(bodyMetricsProvider).valueOrNull ?? <BodyMetric>[];
    final settings = ref.read(settingsProvider).valueOrNull;
    final lastMetric = metricsList.isEmpty ? null : metricsList.first;
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _saved = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.pop(context);
      }
    });

    double? weightValue = ref.read(bodyMetricsProvider.notifier).currentWeight;
    if (weightValue != null && settings?.weightUnit == 'lb') {
      weightValue = weightValue * 2.20462;
    }

    _weightController = TextEditingController(
      text: weightValue?.toStringAsFixed(1) ?? '',
    );
    _bodyFatController = TextEditingController(
      text: lastMetric?.bodyFat?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _shake.dispose();
    _saved.dispose();
    super.dispose();
  }

  void _refuse(String error) {
    setState(() => _error = error);
    HapticFeedback.mediumImpact();
    if (!AppMotion.reduceMotion(context)) _shake.forward(from: 0);
  }

  void _save() {
    if (_saved.isAnimating || _saved.isCompleted) return;
    final l10n = AppLocalizations.of(context)!;
    final imperial = ref.read(settingsProvider).valueOrNull?.weightUnit == 'lb';
    final perKg = imperial ? 2.20462 : 1.0;
    final minWeight = PlanLimits.minWeightKg * perKg;
    final maxWeight = PlanLimits.maxWeightKg * perKg;

    // A comma is how French, Spanish and Arabic keyboards write a decimal:
    // "70,5" was rejected, and the button then did nothing at all. Any
    // positive number was accepted otherwise, 5000 kg included.
    final weight = parseDecimalInput(_weightController.text);
    if (weight == null || weight < minWeight || weight > maxWeight) {
      _refuse(
        l10n.settings_value_out_of_range(
          minWeight.toStringAsFixed(0),
          maxWeight.toStringAsFixed(0),
        ),
      );
      return;
    }

    final fatText = _bodyFatController.text.trim();
    final bodyFat = fatText.isEmpty ? null : parseDecimalInput(fatText);
    if (fatText.isNotEmpty &&
        (bodyFat == null || bodyFat < _minBodyFat || bodyFat > _maxBodyFat)) {
      _refuse(l10n.settings_value_out_of_range('$_minBodyFat', '$_maxBodyFat'));
      return;
    }

    // Body fat was asked for, prefilled, and then thrown away.
    ref
        .read(bodyMetricsProvider.notifier)
        .logWeight(weight / perKg, bodyFat: bodyFat);
    if (AppMotion.reduceMotion(context)) {
      Navigator.pop(context);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {});
    _saved.forward();
  }

  void _clearError(String _) {
    // Also redraws the change from last time as the number is typed.
    setState(() => _error = null);
  }

  /// "−0.4 kg since Sep 25": what the typed weight would change, or null
  /// while there is nothing to compare or the number will not do.
  String? _changeText(AppLocalizations l10n, bool imperial, String unit) {
    // The last weigh-in, newest first.
    final metrics = ref.watch(bodyMetricsProvider).valueOrNull;
    final last = metrics == null || metrics.isEmpty ? null : metrics.first;
    final typed = parseDecimalInput(_weightController.text);
    if (last == null || typed == null) return null;
    final perKg = imperial ? 2.20462 : 1.0;
    if (typed < PlanLimits.minWeightKg * perKg ||
        typed > PlanLimits.maxWeightKg * perKg) {
      return null;
    }
    final change = typed - last.weight * perKg;
    final amount =
        '${change <= 0 ? '−' : '+'}${change.abs().toStringAsFixed(1)} $unit';
    return l10n.progress_change_since(
      amount,
      DateFormat.MMMd(l10n.localeName).format(last.date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final weightUnit = settings?.weightUnit ?? 'kg';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final change = _changeText(
      l10n,
      weightUnit == 'lb',
      localizeUnit(context, weightUnit),
    );
    final done = _saved.isAnimating || _saved.isCompleted;
    return Container(
      decoration: BoxDecoration(
        color: _settingsBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // Use standard bottom sheet padding + keyboard insets
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : _settingsLine,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 24),
              Reveal(
                delay: const Duration(milliseconds: 120),
                offset: const Offset(0, 16),
                child: AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            WaznIcons.weight,
                            color: _settingsGreenText,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context)!.report_log_weight,
                            style: AppTypography.heading3.copyWith(
                              color: _settingsText(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _shake,
                        builder: (context, child) {
                          final t = _shake.value;
                          return Transform.translate(
                            key: const ValueKey('weight-field-shake'),
                            offset: Offset(
                              math.sin(t * math.pi * 5) * 9 * (1 - t),
                              0,
                            ),
                            child: child,
                          );
                        },
                        child: TextField(
                          controller: _weightController,
                          autofocus: true, // Auto-focus for better UX
                          onChanged: _clearError,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.weight_hint,
                            suffixText: localizeUnit(context, weightUnit),
                          ),
                        ),
                      ),
                      // The change the new number makes since last time,
                      // following along as it is typed.
                      AnimatedSize(
                        duration: AppMotion.maybeZero(
                          context,
                          AppMotion.standard,
                        ),
                        curve: Curves.easeOutCubic,
                        alignment: AlignmentDirectional.topStart,
                        child:
                            change == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Reveal(
                                      offset: const Offset(0, -6),
                                      scale: .9,
                                      duration: const Duration(
                                        milliseconds: 380,
                                      ),
                                      curve: AppMotion.springCurve,
                                      child: Container(
                                        key: const ValueKey(
                                          'weight-change-chip',
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _settingsGreenText.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          change,
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color:
                                                    isDark
                                                        ? const Color(
                                                          0xFF6EE7B7,
                                                        )
                                                        : _settingsGreenText,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bodyFatController,
                        onChanged: _clearError,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.body_fat_hint,
                          suffixText: '%',
                        ),
                      ),
                      // The reason slides down under the box rather than
                      // just appearing.
                      AnimatedSize(
                        duration: AppMotion.maybeZero(
                          context,
                          AppMotion.standard,
                        ),
                        curve: Curves.easeOutCubic,
                        alignment: AlignmentDirectional.topStart,
                        child:
                            _error == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Reveal(
                                    key: ValueKey(_error),
                                    offset: const Offset(0, -6),
                                    duration: AppMotion.expansion,
                                    child: Text(
                                      _error!,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: const Color(0xFFE05A47),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Reveal(
                delay: const Duration(milliseconds: 220),
                offset: const Offset(0, 16),
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: _settingsGreen,
                    foregroundColor: const Color(0xFFF0FDF4),
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.standard,
                    transitionBuilder:
                        (child, animation) => ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: AppMotion.springCurve,
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                    child:
                        done
                            ? const Icon(
                              WaznIcons.check,
                              key: ValueKey('weight-saved'),
                              size: 24,
                            )
                            : Text(
                              AppLocalizations.of(
                                context,
                              )!.common_save_progress,
                              key: const ValueKey('weight-save'),
                            ),
                  ),
                ),
              ),
              // Extra space for bottom safe area when keyboard is closed
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
