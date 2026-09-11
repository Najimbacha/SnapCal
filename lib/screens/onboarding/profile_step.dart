import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapcal/widgets/app_icon.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_components.dart';
import 'onboarding_conversions.dart';
import 'onboarding_draft.dart';
import 'onboarding_ui.dart';
import 'onboarding_validation.dart';

class ProfileStep extends StatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  const ProfileStep({super.key, required this.draft, required this.onChanged});

  @override
  State<ProfileStep> createState() => ProfileStepState();
}

class ProfileStepState extends State<ProfileStep> {
  MeasurementSystem _system = MeasurementSystem.metric;
  BiologicalSex? _sex;
  int _age = 28;
  double _heightCm = 170;
  double _weightKg = 75;

  String? _sexError;
  String? _heightError;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    _system = widget.draft.measurementSystem;
    _sex = widget.draft.sex;
    _age = widget.draft.age ?? 28;
    _heightCm = widget.draft.heightCm ?? 170;
    _weightKg = widget.draft.currentWeightKg ?? 75;
  }

  bool validateAndSubmit() {
    _sexError = null;
    _heightError = null;
    _weightError = null;

    final l10n = AppLocalizations.of(context)!;
    var hasErrors = false;

    if (OnboardingValidation.validateAge(_age) != null) hasErrors = true;

    if (_sex == null) {
      _sexError = l10n.onboarding_error_sex_required;
      hasErrors = true;
    }

    final heightErr = OnboardingValidation.validateHeightCm(_heightCm);
    if (heightErr != null) {
      _heightError = _localizeValErr(heightErr, l10n);
      hasErrors = true;
    }

    final weightErr = OnboardingValidation.validateWeightKg(_weightKg);
    if (weightErr != null) {
      _weightError = _localizeValErr(weightErr, l10n);
      hasErrors = true;
    }

    if (!hasErrors) {
      widget.onChanged(
        widget.draft.copyWith(
          measurementSystem: _system,
          age: _age,
          sex: _sex,
          heightCm: _heightCm,
          currentWeightKg: _weightKg,
          clearRecommendation: true,
        ),
      );
    }

    setState(() {});
    return !hasErrors;
  }

  String _localizeValErr(OnboardingValidationError err, AppLocalizations l10n) {
    switch (err) {
      case OnboardingValidationError.adultOnly:
        return l10n.onboarding_error_adult_only;
      case OnboardingValidationError.ageRange:
        return l10n.onboarding_error_age;
      case OnboardingValidationError.heightRange:
        return l10n.onboarding_error_height;
      case OnboardingValidationError.weightRange:
        return l10n.onboarding_error_weight;
      default:
        return l10n.onboarding_error_generic;
    }
  }

  void _toggleSystem(MeasurementSystem system) {
    if (_system == system) return;
    HapticFeedback.lightImpact();
    setState(() {
      _heightError = null;
      _weightError = null;
      _system = system;
    });
  }

  void _setSex(BiologicalSex sex) {
    HapticFeedback.selectionClick();
    setState(() {
      _sex = sex;
      _sexError = null;
    });
  }

  bool get _metric => _system == MeasurementSystem.metric;

  int get _heightDisplayValue {
    if (_metric) return _heightCm.round();
    return OnboardingConversions.cmToInch(_heightCm).round().clamp(20, 118);
  }

  int get _weightDisplayValue {
    if (_metric) return _weightKg.round();
    return OnboardingConversions.kgToLb(_weightKg).round().clamp(44, 1102);
  }

  static List<int> _range(int min, int max) {
    return List<int>.generate(max - min + 1, (index) => min + index);
  }

  String _formatImperialHeight(int totalInches) {
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return '$feet ft $inches in';
  }

  Future<void> _pickAge(BuildContext context, AppLocalizations l10n) async {
    final value = await showAppleWheelPicker<int>(
      context: context,
      title: l10n.onboarding_age,
      values: _range(18, 120),
      value: _age,
      labelBuilder: (value) => '$value ${l10n.onboarding_age_suffix}',
      pickerKey: const Key('onboarding_age_picker'),
    );
    if (value == null || !mounted) return;
    setState(() => _age = value);
  }

  Future<void> _pickHeight(BuildContext context, AppLocalizations l10n) async {
    final values = _metric ? _range(50, 300) : _range(20, 118);
    final value = await showAppleWheelPicker<int>(
      context: context,
      title: l10n.onboarding_height,
      values: values,
      value: _heightDisplayValue,
      labelBuilder:
          (value) => _metric ? '$value cm' : _formatImperialHeight(value),
      pickerKey: const Key('onboarding_height_picker'),
    );
    if (value == null || !mounted) return;
    setState(() {
      _heightCm =
          _metric
              ? value.toDouble()
              : OnboardingConversions.inchToCm(value.toDouble());
      _heightError = null;
    });
  }

  Future<void> _pickWeight(BuildContext context, AppLocalizations l10n) async {
    final values = _metric ? _range(20, 500) : _range(44, 1102);
    final value = await showAppleWheelPicker<int>(
      context: context,
      title: l10n.onboarding_profile_weight,
      values: values,
      value: _weightDisplayValue,
      labelBuilder: (value) => _metric ? '$value kg' : '$value lb',
      pickerKey: const Key('onboarding_weight_picker'),
    );
    if (value == null || !mounted) return;
    setState(() {
      _weightKg =
          _metric
              ? value.toDouble()
              : OnboardingConversions.lbToKg(value.toDouble());
      _weightError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = _heightDisplayValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnbSectionLabel(text: l10n.onboarding_profile_sex_label),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SexTile(
                icon: AppSymbols.male,
                tint: AppColors.sky,
                label: l10n.onboarding_male,
                selected: _sex == BiologicalSex.male,
                onTap: () => _setSex(BiologicalSex.male),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SexTile(
                icon: AppSymbols.female,
                tint: const Color(0xFFEC4899),
                label: l10n.onboarding_female,
                selected: _sex == BiologicalSex.female,
                onTap: () => _setSex(BiologicalSex.female),
              ),
            ),
          ],
        ),
        if (_sexError != null) OnbErrorText(text: _sexError!),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(child: OnbSectionLabel(text: l10n.onboarding_body_label)),
            OnbUnitToggle(
              value: _system,
              onChanged: _toggleSystem,
              metricLabel: l10n.onboarding_unit_metric,
              imperialLabel: l10n.onboarding_unit_imperial,
            ),
          ],
        ),
        const SizedBox(height: 10),
        OnbValueTile(
          key: const Key('onboarding_age_row'),
          icon: AppSymbols.cake,
          tint: AppColors.fat,
          label: l10n.onboarding_age,
          value: '$_age',
          unit: l10n.onboarding_age_suffix,
          onTap: () => _pickAge(context, l10n),
        ),
        const SizedBox(height: 10),
        OnbValueTile(
          key: const Key('onboarding_height_row'),
          icon: AppSymbols.ruler,
          tint: AppColors.sky,
          label: l10n.onboarding_height,
          value: _metric ? '$height' : '${height ~/ 12}′ ${height % 12}″',
          unit: _metric ? 'cm' : null,
          hasError: _heightError != null,
          onTap: () => _pickHeight(context, l10n),
        ),
        if (_heightError != null) OnbErrorText(text: _heightError!),
        const SizedBox(height: 10),
        OnbValueTile(
          key: const Key('onboarding_weight_row'),
          icon: AppSymbols.scale,
          tint: AppColors.primary,
          label: l10n.onboarding_profile_weight,
          value: '$_weightDisplayValue',
          unit: _metric ? 'kg' : 'lb',
          hasError: _weightError != null,
          onTap: () => _pickWeight(context, l10n),
        ),
        if (_weightError != null) OnbErrorText(text: _weightError!),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppSymbols.shieldCheck,
              size: 16,
              color: context.textMutedColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.onboarding_profile_privacy,
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SexTile extends StatelessWidget {
  const _SexTile({
    required this.icon,
    required this.tint,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    final isDark = context.isDarkMode;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : context.cardBorderColor,
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    selected
                        ? accent.withValues(alpha: isDark ? 0.28 : 0.16)
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: selected ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: tint),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
