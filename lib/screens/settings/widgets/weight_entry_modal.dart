import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/theme/app_typography.dart';
import '../../../providers/metrics_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/ui_blocks.dart';

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

class WeightEntryModal extends StatefulWidget {
  const WeightEntryModal({super.key});

  @override
  State<WeightEntryModal> createState() => _WeightEntryModalState();
}

class _WeightEntryModalState extends State<WeightEntryModal> {
  late final TextEditingController _weightController;
  late final TextEditingController _bodyFatController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MetricsProvider>();
    final settings = context.read<SettingsProvider>();
    final lastMetric = provider.metrics.isEmpty ? null : provider.metrics.first;
    
    double? weightValue = provider.currentWeight;
    if (weightValue != null && settings.weightUnit == 'lb') {
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
    final rawWeight = double.tryParse(_weightController.text);
    if (rawWeight == null || rawWeight <= 0) return;
    
    final settings = context.read<SettingsProvider>();
    double weightInKg = rawWeight;
    if (settings.weightUnit == 'lb') {
      weightInKg = rawWeight / 2.20462;
    }

    final bodyFat = double.tryParse(_bodyFatController.text);
    context.read<MetricsProvider>().logWeight(weightInKg, bodyFat: bodyFat);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
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
                  color: isDark
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
                        const Icon(LucideIcons.scale, color: _settingsGreenText),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.settings_body_profile,
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.weight_hint,
                        suffixText: settings.weightUnit,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyFatController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.body_fat_hint,
                        suffixText: '%',
                      ),
                    ),
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
