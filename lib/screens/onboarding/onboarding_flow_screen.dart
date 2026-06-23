import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/widgets/app_icon.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/calorie_onboarding_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/auth_notifier_provider.dart';
import 'onboarding_draft.dart';
import 'onboarding_components.dart';
import 'onboarding_pace_calculator.dart';
import 'welcome_step.dart';
import 'goal_step.dart';
import 'profile_step.dart';
import 'pace_step.dart';
import 'activity_step.dart';
import 'plan_result_step.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  int _stepIndex = 0;
  late OnboardingDraft _draft;
  bool _isCompleting = false;
  final GlobalKey<ProfileStepState> _profileKey = GlobalKey<ProfileStepState>();
  final GlobalKey<PaceStepState> _paceKey = GlobalKey<PaceStepState>();

  @override
  void initState() {
    super.initState();
    _draft = const OnboardingDraft();
  }

  /// The last step index depends on whether pace screen is needed
  int get _lastStep =>
      _draft.goalType == GoalType.loseWeight ||
              _draft.goalType == GoalType.buildMuscle
          ? 5
          : 4;

  /// The index where activity lives (after pace or after profile)
  int get _activityStep =>
      _draft.goalType == GoalType.loseWeight ||
              _draft.goalType == GoalType.buildMuscle
          ? 4
          : 3;

  bool get _showBack => _stepIndex > 0 && _stepIndex < _lastStep;

  bool get _showProgress => _stepIndex > 0 && _stepIndex < _lastStep;

  bool get _isLastStep => _stepIndex == _lastStep;

  bool get _canAdvance {
    switch (_stepIndex) {
      case 0:
        return true;
      case 1:
        return _draft.goalType != null;
      case 2:
        return true; // validation happens on tap via ProfileStep
      case 3:
        if (_draft.goalType == GoalType.loseWeight ||
            _draft.goalType == GoalType.buildMuscle) {
          return true; // validation happens on tap via PaceStep
        }
        return _draft.activityLevel != null;
      case 4:
        return _draft.activityLevel != null;
      default:
        return false;
    }
  }

  void _handleNext() {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    // Profile step → validate, then advance to next screen
    if (_stepIndex == 2) {
      if (!_profileKey.currentState!.validateAndSubmit()) {
        setState(() {}); // show validation errors
        return;
      }
      setState(() => _stepIndex++);
      return;
    }

    // Pace step → validate, then advance to activity
    if (_stepIndex == 3 &&
        (_draft.goalType == GoalType.loseWeight ||
            _draft.goalType == GoalType.buildMuscle)) {
      if (!_paceKey.currentState!.validateAndSubmit()) {
        setState(() {}); // show validation errors
        return;
      }
      setState(() => _stepIndex++);
      return;
    }

    // Activity step → compute recommendation
    if (_stepIndex == _activityStep) {
      _computeRecommendation();
      return;
    }

    setState(() => _stepIndex++);
  }

  void _computeRecommendation() {
    if (_draft.age == null ||
        _draft.sex == null ||
        _draft.heightCm == null ||
        _draft.currentWeightKg == null ||
        _draft.activityLevel == null) {
      return;
    }

    final languageCode = ref.read(settingsProvider).valueOrNull?.languageCode ?? 'en';

    final needsPace =
        _draft.goalType == GoalType.loseWeight ||
        _draft.goalType == GoalType.buildMuscle;
    final timelineMonths =
        needsPace && _draft.pace != null
            ? OnboardingPaceCalculator.deriveTimelineMonths(
              _draft.weightDeltaKg,
              OnboardingPaceCalculator.weeklyRateKgFor(
                _draft.goalType!,
                _draft.pace!,
              ),
            )
            : 1;

    final selectedWeeklyRateKg =
        needsPace && _draft.pace != null
            ? OnboardingPaceCalculator.weeklyRateKgFor(
              _draft.goalType!,
              _draft.pace!,
            )
            : null;

    final profile = OnboardingProfileInput(
      age: _draft.age!,
      gender: _draft.sex!.serviceValue,
      heightCm: _draft.heightCm!,
      currentWeightKg: _draft.currentWeightKg!,
      goalWeightKg: _draft.goalType!.resolveGoalWeightKg(
        currentWeightKg: _draft.currentWeightKg!,
        targetWeightKg: _draft.targetWeightKg,
      ),
      timelineMonths: timelineMonths,
      activityLevel: _draft.activityLevel!.serviceValue,
      weightUnit:
          _draft.measurementSystem == MeasurementSystem.metric ? 'kg' : 'lb',
      heightUnit:
          _draft.measurementSystem == MeasurementSystem.metric ? 'cm' : 'in',
      selectedWeeklyRateKg: selectedWeeklyRateKg,
    );

    final recommendation = CalorieOnboardingService().computeBasePlan(
      profile,
      languageCode: languageCode,
    );

    setState(() {
      _draft = _draft.copyWith(recommendation: recommendation);
      _stepIndex = _lastStep;
    });
  }

  Future<void> _handleFinish() async {
    if (_isCompleting || !_draft.isComplete) return;
    setState(() => _isCompleting = true);
    HapticFeedback.heavyImpact();

    final settings = ref.read(settingsProvider.notifier);
    final metrics = ref.read(bodyMetricsProvider.notifier);

    final needsPace =
        _draft.goalType == GoalType.loseWeight ||
        _draft.goalType == GoalType.buildMuscle;
    final timelineMonths =
        needsPace && _draft.pace != null
            ? OnboardingPaceCalculator.deriveTimelineMonths(
              _draft.weightDeltaKg,
              OnboardingPaceCalculator.weeklyRateKgFor(
                _draft.goalType!,
                _draft.pace!,
              ),
            )
            : 1;

    final finishNeedsPace =
        _draft.goalType == GoalType.loseWeight ||
        _draft.goalType == GoalType.buildMuscle;
    final finishSelectedRate =
        finishNeedsPace && _draft.pace != null
            ? OnboardingPaceCalculator.weeklyRateKgFor(
              _draft.goalType!,
              _draft.pace!,
            )
            : null;

    final profile = OnboardingProfileInput(
      age: _draft.age!,
      gender: _draft.sex!.serviceValue,
      heightCm: _draft.heightCm!,
      currentWeightKg: _draft.currentWeightKg!,
      goalWeightKg: _draft.goalType!.resolveGoalWeightKg(
        currentWeightKg: _draft.currentWeightKg!,
        targetWeightKg: _draft.targetWeightKg,
      ),
      timelineMonths: timelineMonths,
      activityLevel: _draft.activityLevel!.serviceValue,
      weightUnit:
          _draft.measurementSystem == MeasurementSystem.metric ? 'kg' : 'lb',
      heightUnit:
          _draft.measurementSystem == MeasurementSystem.metric ? 'cm' : 'in',
      selectedWeeklyRateKg: finishSelectedRate,
    );

    try {
      await settings.completeOnboarding(
        profile: profile,
        recommendation: _draft.recommendation!,
      );
      await metrics.logWeight(_draft.currentWeightKg!);
    } catch (e) {
      debugPrint('OnboardingFlow: Error completing onboarding: $e');
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.onboarding_finish_error),
        ),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    context.go('/');
  }

  void _handleAdjust() {
    HapticFeedback.lightImpact();
    final needsPace =
        _draft.goalType == GoalType.loseWeight ||
        _draft.goalType == GoalType.buildMuscle;
    if (needsPace) {
      setState(() => _stepIndex = 3);
    } else {
      setState(() => _stepIndex = _activityStep);
    }
  }

  void _handleBack() {
    if (_stepIndex == 0) return;
    HapticFeedback.lightImpact();
    setState(() => _stepIndex--);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          const _OnboardingBackdrop(),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                if (_showBack || _showProgress)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      bottom: 8,
                      left: 22,
                      right: 22,
                    ),
                    child: Row(
                      children: [
                        if (_showBack)
                          GestureDetector(
                            onTap: _handleBack,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.055)
                                        : Colors.white.withValues(alpha: 0.86),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: context.cardBorderColor.withValues(
                                    alpha: isDark ? 0.75 : 1.0,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.18 : 0.04,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                AppSymbols.chevronLeft,
                                size: 18,
                                color: context.textPrimaryColor,
                              ),
                            ),
                          ),
                        if (_showBack) const SizedBox(width: 14),
                        if (_showProgress)
                          Expanded(
                            child: _ProgressRail(fraction: _progressFraction),
                          ),
                      ],
                    ),
                  ),

                // Step content
                Expanded(
                  child: StepPageTransition(
                    child: Center(
                      key: ValueKey('step$_stepIndex'),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 520),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _StepContentFrame(
                          scrollable: true,
                          child: _buildStep(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom button area (hidden on welcome and result screens)
                if (_stepIndex > 0 && !_isLastStep)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      12,
                      24,
                      ((keyboardOpen ? 12 : bottomPadding + 16).clamp(
                        16,
                        48,
                      )).toDouble(),
                    ),
                    child: PrimaryButton(
                      text: _getButtonLabel(l10n),
                      onTap: _canAdvance ? _handleNext : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get _progressFraction {
    if (!_showProgress) return 0.0;
    final needsPace =
        _draft.goalType == GoalType.loseWeight ||
        _draft.goalType == GoalType.buildMuscle;
    final denominator = needsPace ? 5.0 : 4.0;
    if (_stepIndex == _lastStep) return 0.0;
    if (!needsPace && _stepIndex > 2) {
      // welcome(0) goal(1) profile(2) activity(3) → progress skips pace
      return (_stepIndex - 1) / denominator;
    }
    return _stepIndex / denominator;
  }

  String _getButtonLabel(AppLocalizations l10n) {
    return l10n.onboarding_continue;
  }

  Widget _buildStep() {
    final needsPace =
        _draft.goalType == GoalType.loseWeight ||
        _draft.goalType == GoalType.buildMuscle;

    switch (_stepIndex) {
      case 0:
        return WelcomeStep(onGetStarted: _handleNext);
      case 1:
        return GoalStep(
          selected: _draft.goalType,
          onChanged:
              (goal) =>
                  setState(() => _draft = _draft.copyWith(goalType: goal)),
        );
      case 2:
        return ProfileStep(
          key: _profileKey,
          draft: _draft,
          onChanged: (draft) => setState(() => _draft = draft),
        );
      case 3:
        if (needsPace) {
          return PaceStep(
            key: _paceKey,
            draft: _draft,
            onChanged: (draft) => setState(() => _draft = draft),
            onSkip: _handleNext,
          );
        }
        return ActivityStep(
          selected: _draft.activityLevel,
          onChanged:
              (level) => setState(
                () => _draft = _draft.copyWith(activityLevel: level),
              ),
        );
      case 4:
        if (needsPace) {
          return ActivityStep(
            selected: _draft.activityLevel,
            onChanged:
                (level) => setState(
                  () => _draft = _draft.copyWith(activityLevel: level),
                ),
          );
        }
        return PlanResultStep(
          draft: _draft,
          onStart: _handleFinish,
          onAdjust: _handleAdjust,
          completing: _isCompleting,
        );
      case 5:
        return PlanResultStep(
          draft: _draft,
          onStart: _handleFinish,
          onAdjust: _handleAdjust,
          completing: _isCompleting,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [
                    context.surfaceColor,
                    context.surfaceColor,
                    context.backgroundColor,
                  ]
                  : [
                    context.surfaceColor,
                    context.surfaceColor,
                    context.backgroundColor,
                  ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.75, -0.95),
                  radius: 0.9,
                  colors: [
                    AppColors.sky.withValues(alpha: isDark ? 0.22 : 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.85, -0.28),
                  radius: 0.8,
                  colors: [
                    AppColors.tertiarySeed.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepContentFrame extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const _StepContentFrame({required this.child, required this.scrollable});

  @override
  Widget build(BuildContext context) {
    if (!scrollable) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}

class _ProgressRail extends StatelessWidget {
  final double fraction;

  const _ProgressRail({required this.fraction});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      height: 9,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.075)
                : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: context.cardBorderColor.withValues(alpha: isDark ? 0.65 : 1.0),
        ),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(
                  alpha: isDark ? 0.28 : 0.18,
                ),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
