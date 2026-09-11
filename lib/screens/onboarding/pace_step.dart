import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:snapcal/widgets/app_icon.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_components.dart';
import 'onboarding_conversions.dart';
import 'onboarding_draft.dart';
import 'onboarding_pace_calculator.dart';
import 'onboarding_ui.dart';
import 'onboarding_validation.dart';

class PaceStep extends StatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;

  const PaceStep({super.key, required this.draft, required this.onChanged});

  @override
  State<PaceStep> createState() => PaceStepState();
}

class PaceStepState extends State<PaceStep> {
  late double _targetKg;
  Pace? _selectedPace;
  String? _targetError;
  String? _paceError;
  bool _triedSubmit = false;

  @override
  void initState() {
    super.initState();
    _targetKg = _coerceTargetKg(
      widget.draft.targetWeightKg ?? _defaultTargetKg(),
    );
    _selectedPace = widget.draft.pace;
  }

  bool get _isValid => _selectedPace != null;

  void _emitChange() {
    final l10n = AppLocalizations.of(context)!;
    _validateInputs(l10n: l10n, showErrors: _triedSubmit);
    widget.onChanged(
      widget.draft.copyWith(
        targetWeightKg: _targetKg,
        pace: _selectedPace,
        clearRecommendation: true,
      ),
    );
    setState(() {});
  }

  String? _validateErr(OnboardingValidationError? err, AppLocalizations l10n) {
    if (err == null) return null;
    switch (err) {
      case OnboardingValidationError.targetMustBeLower:
        return l10n.onboarding_error_target_lower;
      case OnboardingValidationError.targetMustBeHigher:
        return l10n.onboarding_error_target_higher;
      case OnboardingValidationError.targetRange:
        return l10n.onboarding_error_goal_weight;
      default:
        return l10n.onboarding_error_generic;
    }
  }

  bool _validateInputs({
    required AppLocalizations l10n,
    bool showErrors = false,
  }) {
    if (showErrors) _triedSubmit = true;
    final currentKg = widget.draft.currentWeightKg;
    final goal = widget.draft.goalType;
    var hasError = false;

    if (currentKg != null && goal != null) {
      final dirErr = OnboardingValidation.validateTargetDirection(
        goal: goal,
        currentWeightKg: currentKg,
        targetWeightKg: _targetKg,
      );
      if (dirErr != null) {
        if (showErrors) _targetError = _validateErr(dirErr, l10n);
        hasError = true;
      } else {
        final rangeErr = OnboardingValidation.validateTargetWeightKg(
          _targetKg,
          currentKg,
        );
        if (rangeErr != null) {
          if (showErrors) _targetError = _validateErr(rangeErr, l10n);
          hasError = true;
        } else if (showErrors) {
          _targetError = null;
        }
      }
    } else {
      if (showErrors) _targetError = l10n.onboarding_pace_error_target_required;
      hasError = true;
    }

    if (_selectedPace == null) {
      if (showErrors) _paceError = l10n.onboarding_pace_error_pace_required;
      hasError = true;
    } else if (showErrors) {
      _paceError = null;
    }

    if (showErrors) setState(() {});
    return hasError;
  }

  bool validateAndSubmit() {
    final l10n = AppLocalizations.of(context)!;
    return !_validateInputs(l10n: l10n, showErrors: true);
  }

  void _selectPace(Pace p) {
    setState(() {
      _selectedPace = p;
      _paceError = null;
    });
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goal = widget.draft.goalType;
    final system = widget.draft.measurementSystem;
    final unit = OnboardingPaceCalculator.weeklyRateUnit(system);
    final paces = <(Pace, String, String)>[
      (Pace.gentle, l10n.onboarding_pace_gentle, l10n.onboarding_pace_gentle_desc),
      (
        Pace.balanced,
        l10n.onboarding_pace_balanced,
        l10n.onboarding_pace_balanced_desc,
      ),
      (Pace.faster, l10n.onboarding_pace_faster, l10n.onboarding_pace_faster_desc),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTargetCard(system, l10n),
        if (_targetError != null && _triedSubmit)
          OnbErrorText(text: _targetError!),
        const SizedBox(height: 24),
        OnbSectionLabel(text: l10n.onboarding_pace_how_fast),
        const SizedBox(height: 10),
        for (final (pace, label, description) in paces)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OnbChoiceTile(
              title: label,
              subtitle: description,
              badge:
                  pace == Pace.balanced ? l10n.onboarding_pace_recommended : null,
              footer: _RatePill(
                text: l10n.onboarding_pace_weekly_rate(
                  OnboardingPaceCalculator.formatWeeklyRateValue(
                    goal == null
                        ? 0
                        : OnboardingPaceCalculator.weeklyRateKgFor(goal, pace),
                    system,
                  ),
                  unit,
                ),
                selected: _selectedPace == pace,
              ),
              selected: _selectedPace == pace,
              onTap: () => _selectPace(pace),
            ),
          ),
        if (_paceError != null && _triedSubmit) OnbErrorText(text: _paceError!),
        if (_isValid && widget.draft.currentWeightKg != null && goal != null)
          _buildDateSummary(goal, widget.draft.currentWeightKg!, l10n),
      ],
    );
  }

  Widget _buildTargetCard(MeasurementSystem system, AppLocalizations l10n) {
    final values = _targetDisplayValues(system);
    final value = _targetDisplayValue(system, values);
    final index = values.indexOf(value);
    final unit = system == MeasurementSystem.metric ? 'kg' : 'lb';
    final currentKg = widget.draft.currentWeightKg;
    final current =
        currentKg == null
            ? null
            : system == MeasurementSystem.metric
            ? currentKg.round()
            : OnboardingConversions.kgToLb(currentKg).round();
    final difference = current == null ? null : value - current;
    final isDark = context.isDarkMode;

    return Container(
      key: const Key('onboarding_target_weight_row'),
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              _targetError != null && _triedSubmit
                  ? AppColors.dangerRed
                  : context.cardBorderColor,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickTargetWeight(system, values, value),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboarding_pace_target_weight,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$value',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        TextSpan(
                          text: ' $unit',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (difference != null && difference != 0)
                    Text(
                      l10n.onboarding_pace_difference(
                        '${difference > 0 ? '+' : '−'}${difference.abs()} $unit',
                      ),
                      style: TextStyle(
                        color: context.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          _StepperButton(
            icon: AppSymbols.minus,
            enabled: index > 0,
            onTap: () => _stepTarget(values, index - 1, system),
          ),
          const SizedBox(width: 8),
          _StepperButton(
            icon: AppSymbols.plus,
            enabled: index >= 0 && index < values.length - 1,
            onTap: () => _stepTarget(values, index + 1, system),
          ),
        ],
      ),
    );
  }

  void _stepTarget(List<int> values, int index, MeasurementSystem system) {
    if (index < 0 || index >= values.length) return;
    HapticFeedback.selectionClick();
    final selected = values[index];
    setState(() {
      _targetKg =
          system == MeasurementSystem.metric
              ? selected.toDouble()
              : OnboardingConversions.lbToKg(selected.toDouble());
      _targetError = null;
    });
    _emitChange();
  }

  Future<void> _pickTargetWeight(
    MeasurementSystem system,
    List<int> values,
    int value,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showAppleWheelPicker<int>(
      context: context,
      title: l10n.onboarding_pace_target_weight,
      values: values,
      value: value,
      labelBuilder:
          (value) =>
              system == MeasurementSystem.metric ? '$value kg' : '$value lb',
      pickerKey: const Key('onboarding_target_weight_picker'),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _targetKg =
          system == MeasurementSystem.metric
              ? selected.toDouble()
              : OnboardingConversions.lbToKg(selected.toDouble());
      _targetError = null;
    });
    _emitChange();
  }

  double _defaultTargetKg() {
    final current = widget.draft.currentWeightKg ?? 75;
    final goal = widget.draft.goalType;
    final raw = goal == GoalType.buildMuscle ? current + 5 : current - 5;
    return _coerceTargetKg(raw);
  }

  double _coerceTargetKg(double raw) {
    final values = _targetKgValues();
    if (values.isEmpty) return raw.clamp(20.0, 500.0).toDouble();
    return values.reduce(
      (best, value) => (value - raw).abs() < (best - raw).abs() ? value : best,
    );
  }

  List<double> _targetKgValues() {
    final current = widget.draft.currentWeightKg;
    final goal = widget.draft.goalType;
    if (current == null || goal == null) return const [];

    return List<double>.generate(481, (index) => (20 + index).toDouble()).where(
      (target) {
        final direction = OnboardingValidation.validateTargetDirection(
          goal: goal,
          currentWeightKg: current,
          targetWeightKg: target,
        );
        if (direction != null) return false;
        return OnboardingValidation.validateTargetWeightKg(target, current) ==
            null;
      },
    ).toList();
  }

  List<int> _targetDisplayValues(MeasurementSystem system) {
    final values = _targetKgValues();
    if (system == MeasurementSystem.metric) {
      return values.map((value) => value.round()).toList();
    }
    return values
        .map((value) => OnboardingConversions.kgToLb(value).round())
        .toSet()
        .toList()
      ..sort();
  }

  int _targetDisplayValue(MeasurementSystem system, List<int> values) {
    final display =
        system == MeasurementSystem.metric
            ? _targetKg.round()
            : OnboardingConversions.kgToLb(_targetKg).round();
    if (values.contains(display) || values.isEmpty) return display;
    return values.reduce(
      (best, value) =>
          (value - display).abs() < (best - display).abs() ? value : best,
    );
  }

  Widget _buildDateSummary(
    GoalType goal,
    double currentKg,
    AppLocalizations l10n,
  ) {
    final rate = OnboardingPaceCalculator.weeklyRateKgFor(goal, _selectedPace!);
    final date = OnboardingPaceCalculator.estimatedTargetDate(
      currentKg,
      _targetKg,
      rate,
    );
    final formatted = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
    final accent = context.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: context.isDarkMode ? 0.22 : 0.14),
              accent.withValues(alpha: context.isDarkMode ? 0.10 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppSymbols.calendarCheck,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.onboarding_result_reach_by(formatted),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatePill extends StatelessWidget {
  const _RatePill({required this.text, required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            selected
                ? context.primaryColor.withValues(alpha: 0.12)
                : (context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected ? context.primaryColor : context.textSecondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 26,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              enabled
                  ? accent.withValues(alpha: 0.12)
                  : (context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? accent : context.textMutedColor,
        ),
      ),
    );
  }
}
