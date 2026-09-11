import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

class _WeightEntryModalState extends ConsumerState<WeightEntryModal> {
  static const _minBodyFat = 3;
  static const _maxBodyFat = 70;

  late final TextEditingController _weightController;
  String? _error;
  late final TextEditingController _bodyFatController;

  @override
  void initState() {
    super.initState();
    final metricsList =
        ref.read(bodyMetricsProvider).valueOrNull ?? <BodyMetric>[];
    final settings = ref.read(settingsProvider).valueOrNull;
    final lastMetric = metricsList.isEmpty ? null : metricsList.first;

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
    super.dispose();
  }

  void _save() {
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
      setState(
        () =>
            _error = l10n.settings_value_out_of_range(
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
      setState(
        () =>
            _error = l10n.settings_value_out_of_range(
              '$_minBodyFat',
              '$_maxBodyFat',
            ),
      );
      return;
    }

    // Body fat was asked for, prefilled, and then thrown away.
    ref
        .read(bodyMetricsProvider.notifier)
        .logWeight(weight / perKg, bodyFat: bodyFat);
    Navigator.pop(context);
  }

  void _clearError(String _) {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final weightUnit = settings?.weightUnit ?? 'kg';
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.scale,
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
                    TextField(
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
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFFE05A47),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _settingsGreen,
                  foregroundColor: const Color(0xFFF0FDF4),
                ),
                child: Text(AppLocalizations.of(context)!.common_save_progress),
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
