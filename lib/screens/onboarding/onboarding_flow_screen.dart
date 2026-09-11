import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/calorie_onboarding_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/metrics_provider.dart';
import 'onboarding_draft.dart';
import 'onboarding_components.dart';
import 'onboarding_pace_calculator.dart';
import 'onboarding_ui.dart';
import 'welcome_step.dart';
import 'goal_step.dart';
import 'profile_step.dart';
import 'pace_step.dart';
import 'activity_step.dart';
import 'plan_result_step.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  int _stepIndex = 0;
  OnboardingDraft _draft = const OnboardingDraft();
  bool _isCompleting = false;
  final GlobalKey<ProfileStepState> _profileKey = GlobalKey<ProfileStepState>();
  final GlobalKey<PaceStepState> _paceKey = GlobalKey<PaceStepState>();

  bool get _needsPace => _draft.needsPaceStep;

  /// Welcome(0), goal(1), profile(2), pace(3, weight goals only), activity,
  /// then the plan.
  int get _lastStep => _needsPace ? 5 : 4;

  int get _activityStep => _needsPace ? 4 : 3;

  bool get _isLastStep => _stepIndex == _lastStep;

  bool get _isQuestion => _stepIndex > 0 && !_isLastStep;

  /// Questions asked: goal, profile, pace when it applies, activity.
  int get _questionCount => _needsPace ? 4 : 3;

  bool get _canAdvance {
    switch (_stepIndex) {
      case 0:
        return true;
      case 1:
        return _draft.goalType != null;
      case 2:
        return true; // validation happens on tap via ProfileStep
      case 3:
        if (_needsPace) return true; // validation happens on tap via PaceStep
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

    if (_stepIndex == 2) {
      if (!_profileKey.currentState!.validateAndSubmit()) {
        setState(() {});
        return;
      }
      setState(() => _stepIndex++);
      return;
    }

    if (_stepIndex == 3 && _needsPace) {
      if (!_paceKey.currentState!.validateAndSubmit()) {
        setState(() {});
        return;
      }
      setState(() => _stepIndex++);
      return;
    }

    if (_stepIndex == _activityStep) {
      _computeRecommendation();
      return;
    }

    setState(() => _stepIndex++);
  }

  OnboardingProfileInput _profileInput() {
    final selectedRate =
        _needsPace && _draft.pace != null
            ? OnboardingPaceCalculator.weeklyRateKgFor(
              _draft.goalType!,
              _draft.pace!,
            )
            : null;
    return OnboardingProfileInput(
      age: _draft.age!,
      gender: _draft.sex!.serviceValue,
      heightCm: _draft.heightCm!,
      currentWeightKg: _draft.currentWeightKg!,
      goalWeightKg: _draft.goalType!.resolveGoalWeightKg(
        currentWeightKg: _draft.currentWeightKg!,
        targetWeightKg: _draft.targetWeightKg,
      ),
      timelineMonths:
          selectedRate != null
              ? OnboardingPaceCalculator.deriveTimelineMonths(
                _draft.weightDeltaKg,
                selectedRate,
              )
              : 1,
      activityLevel: _draft.activityLevel!.serviceValue,
      weightUnit:
          _draft.measurementSystem == MeasurementSystem.metric ? 'kg' : 'lb',
      heightUnit:
          _draft.measurementSystem == MeasurementSystem.metric ? 'cm' : 'in',
      selectedWeeklyRateKg: selectedRate,
    );
  }

  /// The plan is worked out on the phone, from the answers.
  ///
  /// An AI call used to follow it in the background, for a line of insight
  /// and a tip that no screen showed. It cost a request against the user's
  /// daily allowance on their first minute in the app, and when it finished
  /// after "Adjust" it put the old answers' plan back over the new one.
  void _computeRecommendation() {
    if (_draft.age == null ||
        _draft.sex == null ||
        _draft.heightCm == null ||
        _draft.currentWeightKg == null ||
        _draft.activityLevel == null) {
      return;
    }

    final languageCode =
        ref.read(settingsProvider).valueOrNull?.languageCode ?? 'en';
    final recommendation = CalorieOnboardingService().computeBasePlan(
      _profileInput(),
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

    try {
      await settings.completeOnboarding(
        profile: _profileInput(),
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
    setState(() => _stepIndex = _needsPace ? 3 : _activityStep);
  }

  void _handleBack() {
    if (_stepIndex == 0) return;
    HapticFeedback.lightImpact();
    setState(() => _stepIndex--);
  }

  (String, String?)? _headerFor(AppLocalizations l10n) {
    if (!_isQuestion) return null;
    if (_stepIndex == 1) {
      return (l10n.onboarding_goal_title, l10n.onboarding_goal_sub);
    }
    if (_stepIndex == 2) {
      return (l10n.onboarding_profile_title, l10n.onboarding_profile_sub);
    }
    if (_stepIndex == 3 && _needsPace) {
      return (l10n.onboarding_pace_title, l10n.onboarding_pace_sub);
    }
    return (l10n.onboarding_activity_title, l10n.onboarding_activity_body);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final header = _headerFor(l10n);

    final content =
        header == null
            ? _buildStep()
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                OnbHeader(
                  eyebrow: l10n.onboarding_step_of(_stepIndex, _questionCount),
                  title: header.$1,
                  subtitle: header.$2,
                ),
                const SizedBox(height: 24),
                _buildStep(),
                const SizedBox(height: 16),
              ],
            );

    // Android's back button used to leave onboarding altogether -- and with
    // it every answer given so far. It now steps back, like the arrow.
    return PopScope(
      canPop: _stepIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: context.backgroundColor,
        body: Stack(
          children: [
            const Positioned.fill(child: _OnboardingBackdrop()),
            SafeArea(
              child: Column(
                children: [
                  if (_isQuestion)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Row(
                        children: [
                          OnbBackButton(onTap: _handleBack),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OnbProgress(
                              count: _questionCount,
                              current: _stepIndex,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: StepPageTransition(
                      child: KeyedSubtree(
                        key: ValueKey('step$_stepIndex'),
                        child: _StepScroll(
                          center: header == null,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: content,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isQuestion)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        10,
                        24,
                        ((keyboardOpen ? 12 : bottomPadding + 14).clamp(
                          16,
                          48,
                        )).toDouble(),
                      ),
                      child: OnbPrimaryButton(
                        key: const ValueKey('onboarding-continue'),
                        label: l10n.onboarding_continue,
                        onTap: _canAdvance ? _handleNext : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_stepIndex) {
      case 0:
        return WelcomeStep(onGetStarted: _handleNext);
      case 1:
        return GoalStep(
          selected: _draft.goalType,
          onChanged:
              (goal) => setState(
                () =>
                    _draft = _draft.copyWith(
                      goalType: goal,
                      clearRecommendation: true,
                    ),
              ),
        );
      case 2:
        return ProfileStep(
          key: _profileKey,
          draft: _draft,
          onChanged: (draft) => setState(() => _draft = draft),
        );
      case 3:
        if (_needsPace) {
          return PaceStep(
            key: _paceKey,
            draft: _draft,
            onChanged: (draft) => setState(() => _draft = draft),
          );
        }
        return _activity();
      case 4:
        if (_needsPace) return _activity();
        return _plan();
      case 5:
        return _plan();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _activity() => ActivityStep(
    selected: _draft.activityLevel,
    onChanged:
        (level) => setState(
          () =>
              _draft = _draft.copyWith(
                activityLevel: level,
                clearRecommendation: true,
              ),
        ),
  );

  Widget _plan() => PlanResultStep(
    draft: _draft,
    onStart: _handleFinish,
    onAdjust: _handleAdjust,
    completing: _isCompleting,
  );
}

/// Scrolls a step, and centres the ones without a header (welcome, plan)
/// when they are shorter than the screen.
class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.child, required this.center});

  final Widget child;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: center ? Alignment.center : Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    Widget glow(Color color, double alpha, double size) => IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: ColoredBox(color: context.backgroundColor)),
        Positioned(
          top: -140,
          right: -110,
          child: glow(AppColors.primary, isDark ? 0.22 : 0.16, 360),
        ),
        Positioned(
          top: 280,
          left: -150,
          child: glow(AppColors.tertiarySeed, isDark ? 0.10 : 0.07, 320),
        ),
      ],
    );
  }
}
