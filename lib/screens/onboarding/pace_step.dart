import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:snapcal/widgets/app_icon.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import 'onboarding_components.dart';
import 'onboarding_draft.dart';
import 'onboarding_conversions.dart';
import 'onboarding_pace_calculator.dart';
import 'onboarding_validation.dart';

class PaceStep extends StatefulWidget {
  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;
  final VoidCallback onSkip;

  const PaceStep({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onSkip,
  });

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
    final hasError = _validateInputs(l10n: l10n, showErrors: _triedSubmit);
    widget.onChanged(
      widget.draft.copyWith(
        targetWeightKg: _targetKg,
        pace: _selectedPace,
        clearRecommendation: true,
      ),
    );
    if (!hasError && _selectedPace != null) {
      setState(() {});
    }
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
      case OnboardingValidationError.targetExtreme:
        return l10n.onboarding_error_generic;
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
        } else {
          if (showErrors) _targetError = null;
        }
      }
    } else {
      if (showErrors) _targetError = l10n.onboarding_pace_error_target_required;
      hasError = true;
    }

    if (_selectedPace == null) {
      if (showErrors) _paceError = l10n.onboarding_pace_error_pace_required;
      hasError = true;
    } else {
      if (showErrors) _paceError = null;
    }

    if (showErrors) setState(() {});
    return hasError;
  }

  bool validateAndSubmit() {
    final l10n = AppLocalizations.of(context)!;
    return !_validateInputs(l10n: l10n, showErrors: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goal = widget.draft.goalType;
    final system = widget.draft.measurementSystem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          l10n.onboarding_pace_title,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 22),
        _buildTargetPicker(system),
        if (_targetError != null && _triedSubmit)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 6),
            child: Text(
              _targetError!,
              style: const TextStyle(
                color: AppColors.dangerRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 20),
        // Pace cards
        _PaceCard(
          label: l10n.onboarding_pace_gentle,
          subtitle: l10n.onboarding_pace_gentle_desc,
          pace: Pace.gentle,
          goal: goal,
          system: system,
          selected: _selectedPace == Pace.gentle,
          onTap: () => _selectPace(Pace.gentle),
        ),
        const SizedBox(height: 12),
        _PaceCard(
          label: l10n.onboarding_pace_balanced,
          subtitle: l10n.onboarding_pace_balanced_desc,
          pace: Pace.balanced,
          goal: goal,
          system: system,
          selected: _selectedPace == Pace.balanced,
          onTap: () => _selectPace(Pace.balanced),
        ),
        const SizedBox(height: 12),
        _PaceCard(
          label: l10n.onboarding_pace_faster,
          subtitle: l10n.onboarding_pace_faster_desc,
          pace: Pace.faster,
          goal: goal,
          system: system,
          selected: _selectedPace == Pace.faster,
          onTap: () => _selectPace(Pace.faster),
        ),
        if (_paceError != null && _triedSubmit)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 6),
            child: Text(
              _paceError!,
              style: const TextStyle(
                color: AppColors.dangerRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Estimated date summary (only when valid)
        if (_isValid && widget.draft.currentWeightKg != null && goal != null)
          _buildDateSummary(
            goal,
            _targetKg,
            widget.draft.currentWeightKg!,
            system,
          ),
      ],
    );
  }

  void _selectPace(Pace p) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPace = p;
      _paceError = null;
      _triedSubmit = true;
    });
    _emitChange();
  }

  Widget _buildTargetPicker(MeasurementSystem system) {
    final values = _targetDisplayValues(system);
    final value = _targetDisplayValue(system, values);

    return AppleValuePickerRow(
      rowKey: const Key('onboarding_target_weight_row'),
      label: AppLocalizations.of(context)!.onboarding_pace_target_weight,
      value: system == MeasurementSystem.metric ? '$value kg' : '$value lb',
      onTap: () => _pickTargetWeight(system, values, value),
    );
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
    if (values.contains(display)) return display;
    if (values.isEmpty) return display;
    return values.reduce(
      (best, value) =>
          (value - display).abs() < (best - display).abs() ? value : best,
    );
  }

  Widget _buildDateSummary(
    GoalType goal,
    double targetKg,
    double currentKg,
    MeasurementSystem system,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final rate = OnboardingPaceCalculator.weeklyRateKgFor(goal, _selectedPace!);
    final date = OnboardingPaceCalculator.estimatedTargetDate(
      currentKg,
      targetKg,
      rate,
    );
    final formatted = DateFormat.yMMMMd().format(date);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(AppSymbols.calendar, size: 16, color: context.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.onboarding_pace_target_date(formatted),
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaceCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final Pace pace;
  final GoalType? goal;
  final MeasurementSystem system;
  final bool selected;
  final VoidCallback onTap;

  const _PaceCard({
    required this.label,
    required this.subtitle,
    required this.pace,
    required this.goal,
    required this.system,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final accent = context.primaryColor;
    final rateKg =
        goal != null
            ? OnboardingPaceCalculator.weeklyRateKgFor(goal!, pace)
            : 0.0;
    final rateValue = OnboardingPaceCalculator.formatWeeklyRateValue(
      rateKg,
      system,
    );
    final unit = OnboardingPaceCalculator.weeklyRateUnit(system);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color:
              selected
                  ? accent.withValues(alpha: isDark ? 0.12 : 0.07)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.045)
                      : Colors.white.withValues(alpha: 0.9)),
          borderRadius: BorderRadius.circular(20),
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
                      color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.10 : 0.025,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
        ),
        child: Stack(
          children: [
            if (selected)
              PositionedDirectional(
                start: 0,
                top: 16,
                bottom: 16,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.24,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Rate pill
                Container(
                  constraints: const BoxConstraints(maxWidth: 104),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? accent.withValues(alpha: 0.12)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.025)),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color:
                          selected
                              ? accent.withValues(alpha: 0.3)
                              : context.cardBorderColor,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.onboarding_pace_weekly_rate(rateValue, unit),
                    style: TextStyle(
                      color: selected ? accent : context.textSecondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                // Selection radio
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: selected ? AppColors.primaryGradient : null,
                    color: selected ? null : Colors.transparent,
                    border: Border.all(
                      color:
                          selected
                              ? Colors.transparent
                              : context.textMutedColor,
                      width: selected ? 0 : 1.5,
                    ),
                  ),
                  child:
                      selected
                          ? Icon(
                            AppSymbols.check,
                            size: 14,
                            color: isDark ? Colors.black : Colors.white,
                          )
                          : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
