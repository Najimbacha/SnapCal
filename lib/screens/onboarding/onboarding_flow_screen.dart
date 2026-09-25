import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/services/calorie_onboarding_service.dart';
import '../../data/services/first_meal_guide_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/settings_provider.dart';
import 'body_steps.dart';
import 'building_step.dart';
import 'choice_steps.dart';
import 'onboarding_body.dart';
import 'onboarding_draft.dart';
import 'onboarding_kit.dart';
import 'onboarding_pace_calculator.dart';
import 'onboarding_units.dart';
import 'pace_step.dart';
import 'plan_result_step.dart';
import 'target_step.dart';
import 'welcome_step.dart';

enum _Step {
  welcome,
  goal,
  sex,
  age,
  height,
  weight,
  activity,
  target,
  pace,
  building,
  plan,
}

const _questions = {
  _Step.goal,
  _Step.sex,
  _Step.age,
  _Step.height,
  _Step.weight,
  _Step.activity,
  _Step.target,
  _Step.pace,
};

/// One question per screen: goal, sex, age, height, weight, activity, then
/// target weight and pace for the two weight goals. Height comes before
/// weight so the weight screen's BMI is right.
///
/// The screens only collect answers. The plan is built by
/// [CalorieOnboardingService] and saved by `completeOnboarding`, exactly as
/// before, so nothing downstream changes.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  _Step _step = _Step.welcome;
  bool _forward = true;
  bool _completing = false;

  // Rulers always show a value, so the body answers start filled in.
  OnboardingDraft _draft = const OnboardingDraft(
    age: 28,
    heightCm: 170,
    currentWeightKg: 75,
  );

  List<_Step> get _steps => [
    _Step.welcome,
    _Step.goal,
    _Step.sex,
    _Step.age,
    _Step.height,
    _Step.weight,
    _Step.activity,
    if (_draft.needsPaceStep) ...[_Step.target, _Step.pace],
    _Step.building,
    _Step.plan,
  ];

  List<_Step> get _questionSteps =>
      _steps.where(_questions.contains).toList(growable: false);

  bool get _isLastQuestion => _questionSteps.last == _step;

  int get _age => _draft.age ?? 28;

  TargetCheck? get _targetCheck {
    final goal = _draft.goalType;
    final target = _draft.targetWeightKg;
    if (goal == null || target == null) return null;
    return checkTarget(
      goal: goal,
      currentKg: _draft.currentWeightKg!,
      targetKg: target,
      heightCm: _draft.heightCm!,
    );
  }

  bool get _canContinue => switch (_step) {
    _Step.goal => _draft.goalType != null,
    _Step.sex => _draft.sex != null,
    _Step.activity => _draft.activityLevel != null,
    _Step.target => _targetCheck?.isOk ?? false,
    _ => true,
  };

  void _update(OnboardingDraft draft) =>
      setState(() => _draft = draft.copyWith(clearRecommendation: true));

  void _go(_Step step, {required bool forward}) {
    _prepare(step);
    setState(() {
      _forward = forward;
      _step = step;
    });
  }

  /// Fills in what a screen needs before it is shown.
  void _prepare(_Step step) {
    final goal = _draft.goalType;
    if (step == _Step.target && goal != null) {
      final check = _targetCheck;
      final directionWrong =
          check?.issue == TargetIssue.mustBeLower ||
          check?.issue == TargetIssue.mustBeHigher;
      if (_draft.targetWeightKg == null || directionWrong) {
        final guess = defaultTargetKg(
          goal: goal,
          currentKg: _draft.currentWeightKg!,
          heightCm: _draft.heightCm!,
        );
        // A whole number in the unit on screen; up for weight loss, so the
        // guess never lands under the healthy range.
        final shown = kgToDisplay(guess, _draft.weightSystem);
        final whole =
            goal == GoalType.loseWeight
                ? shown.ceilToDouble()
                : shown.roundToDouble();
        _draft = _draft.copyWith(
          targetWeightKg: displayToKg(whole, _draft.weightSystem),
          clearRecommendation: true,
        );
      }
    }
    if (step == _Step.pace) {
      final pace =
          gentlePaceOnly(age: _age, goal: goal)
              ? Pace.gentle
              : (_draft.pace ?? Pace.balanced);
      _draft = _draft.copyWith(pace: pace, clearRecommendation: true);
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_isLastQuestion) {
      final plan = _buildPlan();
      if (plan == null) return;
      _draft = _draft.copyWith(recommendation: plan);
      _go(_Step.building, forward: true);
      return;
    }
    final steps = _steps;
    final i = steps.indexOf(_step);
    if (i < steps.length - 1) _go(steps[i + 1], forward: true);
  }

  void _back() {
    if (_step == _Step.welcome || _step == _Step.building || _completing) {
      return;
    }
    HapticFeedback.lightImpact();
    final steps = _steps.where((s) => s != _Step.building).toList();
    final i = steps.indexOf(_step);
    if (i > 0) _go(steps[i - 1], forward: false);
  }

  Pace? get _effectivePace {
    if (!_draft.needsPaceStep) return null;
    if (gentlePaceOnly(age: _age, goal: _draft.goalType)) return Pace.gentle;
    return _draft.pace ?? Pace.balanced;
  }

  OnboardingProfileInput? _profileInput({Pace? pace}) {
    final goal = _draft.goalType;
    final sex = _draft.sex;
    final activity = _draft.activityLevel;
    if (goal == null || sex == null || activity == null) return null;
    final chosen = pace ?? _effectivePace;
    final rate =
        chosen == null
            ? null
            : OnboardingPaceCalculator.weeklyRateKgFor(goal, chosen);
    return OnboardingProfileInput(
      age: _age,
      gender: sex.serviceValue,
      heightCm: _draft.heightCm!,
      currentWeightKg: _draft.currentWeightKg!,
      goalWeightKg: goal.resolveGoalWeightKg(
        currentWeightKg: _draft.currentWeightKg!,
        targetWeightKg: _draft.targetWeightKg,
      ),
      timelineMonths:
          rate != null && rate > 0
              ? OnboardingPaceCalculator.deriveTimelineMonths(
                _draft.weightDeltaKg,
                rate,
              )
              : 1,
      activityLevel: activity.serviceValue,
      weightUnit:
          _draft.weightSystem == MeasurementSystem.imperial ? 'lb' : 'kg',
      heightUnit:
          _draft.heightSystem == MeasurementSystem.imperial ? 'in' : 'cm',
      selectedWeeklyRateKg: rate,
    );
  }

  String get _languageCode =>
      ref.read(settingsProvider).valueOrNull?.languageCode ?? 'en';

  /// The plan, worked out on the phone from the answers.
  OnboardingRecommendation? _buildPlan({Pace? pace}) {
    final input = _profileInput(pace: pace);
    if (input == null) return null;
    return CalorieOnboardingService().computeBasePlan(
      input,
      languageCode: _languageCode,
    );
  }

  Future<void> _finish() async {
    if (_completing || !_draft.isComplete) return;
    setState(() => _completing = true);
    HapticFeedback.heavyImpact();

    final settings = ref.read(settingsProvider.notifier);
    final metrics = ref.read(bodyMetricsProvider.notifier);
    try {
      await settings.completeOnboarding(
        profile: _profileInput()!,
        recommendation: _draft.recommendation!,
      );
      await metrics.logWeight(_draft.currentWeightKg!);
      await FirstMealGuideService().schedule();
    } catch (e) {
      debugPrint('OnboardingFlow: Error completing onboarding: $e');
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.onboarding_finish_error),
        ),
      );
      return;
    }
    if (!mounted) return;
    context.go('/');
  }

  String _section(AppLocalizations l10n) => switch (_step) {
    _Step.goal => l10n.onb_section_goal,
    _Step.target || _Step.pace => l10n.onb_section_target,
    _Step.plan => l10n.onb_section_plan,
    _ => l10n.onb_section_about,
  };

  double get _progress {
    if (_step == _Step.plan) return 1;
    final questions = _questionSteps;
    return (questions.indexOf(_step) + 1) / questions.length;
  }

  Widget _body() {
    final d = _draft;
    return switch (_step) {
      _Step.welcome => WelcomeStep(onGetStarted: _next),
      _Step.goal => GoalStep(
        selected: d.goalType,
        onChanged:
            (goal) => _update(
              goal == d.goalType
                  ? d
                  : d.copyWith(
                    goalType: goal,
                    clearTargetWeightKg: true,
                    clearPace: true,
                  ),
            ),
      ),
      _Step.sex => SexStep(
        selected: d.sex,
        onChanged: (sex) => _update(d.copyWith(sex: sex)),
      ),
      _Step.age => AgeStep(
        age: _age,
        onChanged: (age) => _update(_draft.copyWith(age: age)),
      ),
      _Step.height => HeightStep(
        heightCm: d.heightCm!,
        system: d.heightSystem,
        onSystemChanged: (s) => _update(d.copyWith(heightSystem: s)),
        onChanged: (cm) => _update(_draft.copyWith(heightCm: cm)),
      ),
      _Step.weight => WeightStep(
        weightKg: d.currentWeightKg!,
        heightCm: d.heightCm!,
        age: _age,
        system: d.weightSystem,
        onSystemChanged: (s) => _update(d.copyWith(weightSystem: s)),
        onChanged: (kg) => _update(_draft.copyWith(currentWeightKg: kg)),
      ),
      _Step.activity => ActivityStep(
        selected: d.activityLevel,
        onChanged: (level) => _update(d.copyWith(activityLevel: level)),
      ),
      _Step.target => TargetStep(
        goal: d.goalType!,
        currentKg: d.currentWeightKg!,
        targetKg: d.targetWeightKg!,
        heightCm: d.heightCm!,
        system: d.weightSystem,
        onChanged: (kg) => _update(_draft.copyWith(targetWeightKg: kg)),
      ),
      _Step.pace => PaceStep(
        goal: d.goalType!,
        age: _age,
        pace: _effectivePace!,
        currentKg: d.currentWeightKg!,
        targetKg: d.targetWeightKg!,
        system: d.weightSystem,
        planFor: (pace) => _buildPlan(pace: pace)!,
        onChanged: (pace) => _update(d.copyWith(pace: pace)),
      ),
      _Step.building => BuildingStep(
        onDone: () => _go(_Step.plan, forward: true),
      ),
      _Step.plan => PlanResultStep(draft: d),
    };
  }

  Widget? _footer(AppLocalizations l10n) {
    if (_step == _Step.plan) {
      return OnbCta(
        key: const ValueKey('onboarding-start-plan'),
        label: l10n.onboarding_plan_start,
        loading: _completing,
        onTap: _completing ? null : _finish,
      );
    }
    if (!_questions.contains(_step)) return null;
    return OnbCta(
      key: const ValueKey('onboarding-continue'),
      label: _isLastQuestion ? l10n.onb_build_plan : l10n.onboarding_continue,
      onTap: _canContinue ? _next : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final showBar = _questions.contains(_step) || _step == _Step.plan;
    final footer = _footer(l10n);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // New screens come in from the side the user is heading.
    final enterFrom = (_forward ? 1.0 : -1.0) * (rtl ? -1 : 1) * 0.14;

    return PopScope(
      canPop: _step == _Step.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (showBar)
                OnbTopBar(
                  section: _section(l10n),
                  progress: _progress,
                  onBack: _back,
                ),
              Expanded(
                child: AnimatedSwitcher(
                  // The old question leaves quickly; the new one glides in
                  // and its cards follow it up one by one.
                  duration: Duration(milliseconds: reduceMotion ? 0 : 420),
                  reverseDuration: Duration(
                    milliseconds: reduceMotion ? 0 : 240,
                  ),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder:
                      (current, previous) => Stack(
                        children: [...previous, if (current != null) current],
                      ),
                  transitionBuilder: (child, animation) {
                    final incoming = child.key == ValueKey(_step);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: Offset(incoming ? enterFrom : -enterFrom, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: SizedBox.expand(child: _body()),
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    (bottomInset + 14).clamp(18, 48).toDouble(),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: footer,
                    ),
                  ),
                )
              else
                SizedBox(height: bottomInset),
            ],
          ),
        ),
      ),
    );
  }
}
