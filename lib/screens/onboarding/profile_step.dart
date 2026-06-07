import 'package:flutter/material.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/theme_colors.dart';
import 'onboarding_draft.dart';
import 'onboarding_components.dart';
import 'onboarding_conversions.dart';
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

    final ageErr = OnboardingValidation.validateAge(_age);
    if (ageErr != null) {
      hasErrors = true;
    }

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
      _sexError = null;
      _heightError = null;
      _weightError = null;
      _system = system;
    });
  }

  int get _heightDisplayValue {
    if (_system == MeasurementSystem.metric) return _heightCm.round();
    return OnboardingConversions.cmToInch(_heightCm).round().clamp(20, 118);
  }

  int get _weightDisplayValue {
    if (_system == MeasurementSystem.metric) return _weightKg.round();
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

  String _formatHeightValue() {
    return _system == MeasurementSystem.metric
        ? '$_heightDisplayValue cm'
        : _formatImperialHeight(_heightDisplayValue);
  }

  String _formatWeightValue() {
    return _system == MeasurementSystem.metric
        ? '$_weightDisplayValue kg'
        : '$_weightDisplayValue lb';
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
    final values =
        _system == MeasurementSystem.metric ? _range(50, 300) : _range(20, 118);
    final value = await showAppleWheelPicker<int>(
      context: context,
      title: l10n.onboarding_height,
      values: values,
      value: _heightDisplayValue,
      labelBuilder:
          (value) =>
              _system == MeasurementSystem.metric
                  ? '$value cm'
                  : _formatImperialHeight(value),
      pickerKey: const Key('onboarding_height_picker'),
    );
    if (value == null || !mounted) return;
    setState(() {
      _heightCm =
          _system == MeasurementSystem.metric
              ? value.toDouble()
              : OnboardingConversions.inchToCm(value.toDouble());
      _heightError = null;
    });
  }

  Future<void> _pickWeight(BuildContext context, AppLocalizations l10n) async {
    final values =
        _system == MeasurementSystem.metric
            ? _range(20, 500)
            : _range(44, 1102);
    final value = await showAppleWheelPicker<int>(
      context: context,
      title: l10n.onboarding_profile_weight,
      values: values,
      value: _weightDisplayValue,
      labelBuilder:
          (value) =>
              _system == MeasurementSystem.metric ? '$value kg' : '$value lb',
      pickerKey: const Key('onboarding_weight_picker'),
    );
    if (value == null || !mounted) return;
    setState(() {
      _weightKg =
          _system == MeasurementSystem.metric
              ? value.toDouble()
              : OnboardingConversions.lbToKg(value.toDouble());
      _weightError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          l10n.onboarding_profile_title,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 20),
        MeasurementToggle(value: _system, onChanged: _toggleSystem),
        const SizedBox(height: 24),
        AppleValuePickerRow(
          rowKey: const Key('onboarding_age_row'),
          label: l10n.onboarding_age,
          value: '$_age ${l10n.onboarding_age_suffix}',
          onTap: () => _pickAge(context, l10n),
        ),
        const SizedBox(height: 18),
        _FieldLabel(text: l10n.onboarding_profile_sex_label),
        const SizedBox(height: 8),
        _SexSelector(
          sex: _sex,
          maleLabel: l10n.onboarding_male,
          femaleLabel: l10n.onboarding_female,
          error: _sexError,
          onChanged: (s) {
            setState(() => _sex = s);
          },
        ),
        if (_sexError != null) _ErrorText(text: _sexError!),
        const SizedBox(height: 18),
        AppleValuePickerRow(
          rowKey: const Key('onboarding_height_row'),
          label: l10n.onboarding_height,
          value: _formatHeightValue(),
          onTap: () => _pickHeight(context, l10n),
        ),
        if (_heightError != null) _ErrorText(text: _heightError!),
        const SizedBox(height: 18),
        AppleValuePickerRow(
          rowKey: const Key('onboarding_weight_row'),
          label: l10n.onboarding_profile_weight,
          value: _formatWeightValue(),
          onTap: () => _pickWeight(context, l10n),
        ),
        if (_weightError != null) _ErrorText(text: _weightError!),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textSecondaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.dangerRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SexSelector extends StatelessWidget {
  final BiologicalSex? sex;
  final String maleLabel;
  final String femaleLabel;
  final String? error;
  final ValueChanged<BiologicalSex?> onChanged;

  const _SexSelector({
    required this.sex,
    required this.maleLabel,
    required this.femaleLabel,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SexSegment(
            label: maleLabel,
            selected: sex == BiologicalSex.male,
            onTap: () => onChanged(BiologicalSex.male),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SexSegment(
            label: femaleLabel,
            selected: sex == BiologicalSex.female,
            onTap: () => onChanged(BiologicalSex.female),
          ),
        ),
      ],
    );
  }
}

class _SexSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SexSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = context.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              selected
                  ? (isDark
                      ? accent.withValues(alpha: 0.15)
                      : accent.withValues(alpha: 0.08))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.045)
                      : Colors.white.withValues(alpha: 0.86)),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                selected
                    ? accent.withValues(alpha: 0.76)
                    : context.cardBorderColor,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected
                    ? context.textPrimaryColor
                    : context.textSecondaryColor,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
