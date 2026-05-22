import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/calorie_onboarding_service.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/settings_provider.dart';

/// SnapCal Premium Onboarding
/// Re-implemented with full M3 Expressive branding & Google Gemini aesthetics.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const int _totalSteps = 6;

  late final AnimationController _bgController;
  late final AnimationController _entranceController;

  int _stepIndex = 0;
  bool _isImperial = false;
  String _gender = 'male';
  String _activityLevel = 'active';
  double _timelineMonths = 4;
  bool _isLoadingResult = false;
  bool _isCompleting = false;

  final CalorieOnboardingService _service = CalorieOnboardingService();
  OnboardingRecommendation? _recommendation;
  OnboardingProfileInput? _profile;

  late final TextEditingController _ageController;
  late final TextEditingController _heightCmController;
  late final TextEditingController _heightFtController;
  late final TextEditingController _heightInController;
  late final TextEditingController _currentWeightController;
  late final TextEditingController _goalWeightController;

  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _heightCmFocusNode = FocusNode();
  final FocusNode _heightFtFocusNode = FocusNode();
  final FocusNode _heightInFocusNode = FocusNode();
  final FocusNode _currentWeightFocusNode = FocusNode();
  final FocusNode _goalWeightFocusNode = FocusNode();

  String? _errorText;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _isImperial = _usesImperial(locale.countryCode);

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _ageController = TextEditingController(text: '28');
    _heightCmController = TextEditingController(text: '170');
    _heightFtController = TextEditingController(text: '5');
    _heightInController = TextEditingController(text: '7');
    if (_isImperial) {
      _currentWeightController = TextEditingController(text: '165');
      _goalWeightController = TextEditingController(text: '155');
    } else {
      _currentWeightController = TextEditingController(text: '75');
      _goalWeightController = TextEditingController(text: '70');
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    _ageController.dispose();
    _heightCmController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    _ageFocusNode.dispose();
    _heightCmFocusNode.dispose();
    _heightFtFocusNode.dispose();
    _heightInFocusNode.dispose();
    _currentWeightFocusNode.dispose();
    _goalWeightFocusNode.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  bool _usesImperial(String? countryCode) {
    return countryCode == 'US' || countryCode == 'LR' || countryCode == 'MM';
  }

  // --- Logic Methods ---

  Future<void> _handleNext() async {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    if (_stepIndex == 4) {
      final profile = _validateAndBuildProfile();
      if (profile == null) return;
      setState(() {
        _profile = profile;
        _stepIndex = 5;
        _isLoadingResult = true;
        _errorText = null;
        _recommendation = null;
      });
      _generateRecommendation(profile);
      return;
    }

    if (_stepIndex == 5) {
      await _finishOnboarding();
      return;
    }

    if (!_validateCurrentStep()) return;

    setState(() {
      _errorText = null;
      _stepIndex++;
    });
    _entranceController.reset();
    _entranceController.forward();
  }

  void _handleBack() {
    if (_stepIndex == 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _errorText = null;
      _stepIndex--;
    });
    _entranceController.reset();
    _entranceController.forward();
  }

  bool _validateCurrentStep() {
    switch (_stepIndex) {
      case 0:
        return true;
      default:
        return _validateAndBuildProfile(upToStep: _stepIndex) != null;
    }
  }

  OnboardingProfileInput? _validateAndBuildProfile({int? upToStep}) {
    final step = upToStep ?? 4;
    final l10n = AppLocalizations.of(context)!;

    final age = int.tryParse(_ageController.text.trim());
    if (step >= 1 && (age == null || age < 13 || age > 100)) {
      _setError(l10n.onboarding_error_age);
      return null;
    }

    final heightCm = _parseHeightCm();
    if (step >= 1 && (heightCm == null || heightCm < 100 || heightCm > 250)) {
      _setError(l10n.onboarding_error_height);
      return null;
    }

    final currentWeightKg = _parseWeightKg(_currentWeightController.text);
    if (step >= 2 &&
        (currentWeightKg == null ||
            currentWeightKg < 30 ||
            currentWeightKg > 350)) {
      _setError(l10n.onboarding_error_weight);
      return null;
    }

    final goalWeightKg = _parseWeightKg(_goalWeightController.text);
    if (step >= 3 &&
        (goalWeightKg == null || goalWeightKg < 30 || goalWeightKg > 350)) {
      _setError(l10n.onboarding_error_goal_weight);
      return null;
    }

    _errorText = null;
    return OnboardingProfileInput(
      age: age ?? 28,
      gender: _gender,
      heightCm: heightCm ?? 170,
      currentWeightKg: currentWeightKg ?? 0,
      goalWeightKg: goalWeightKg ?? currentWeightKg ?? 0,
      timelineMonths: _timelineMonths.round(),
      activityLevel: _activityLevel,
      weightUnit: _isImperial ? 'lb' : 'kg',
      heightUnit: _isImperial ? 'in' : 'cm',
    );
  }

  void _setError(String text) => setState(() => _errorText = text);

  double? _parseHeightCm() {
    if (!_isImperial) return double.tryParse(_heightCmController.text.trim());
    final feet = int.tryParse(_heightFtController.text.trim());
    final inches = int.tryParse(_heightInController.text.trim());
    if (feet == null || inches == null) return null;
    return ((feet * 12) + inches) * 2.54;
  }

  double? _parseWeightKg(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return null;
    return _isImperial ? parsed * 0.45359237 : parsed;
  }

  void _toggleMeasurementSystem(bool toImperial) {
    if (_isImperial == toImperial) return;
    HapticFeedback.lightImpact();

    final currentHeightCm = _parseHeightCm();
    final currentWeightKg = _parseWeightKg(_currentWeightController.text);
    final goalWeightKg = _parseWeightKg(_goalWeightController.text);

    setState(() {
      _isImperial = toImperial;
      if (currentHeightCm != null) {
        if (toImperial) {
          final totalInches = currentHeightCm / 2.54;
          final f = totalInches ~/ 12;
          final i = (totalInches % 12).round();
          _heightFtController.text = f.toString();
          _heightInController.text = i.toString();
        } else {
          _heightCmController.text = currentHeightCm.round().toString();
        }
      }
      if (currentWeightKg != null) {
        _currentWeightController.text =
            toImperial
                ? (currentWeightKg / 0.45359237).round().toString()
                : currentWeightKg
                    .toStringAsFixed(1)
                    .replaceAll(RegExp(r'\.0$'), '');
      }
      if (goalWeightKg != null) {
        _goalWeightController.text =
            toImperial
                ? (goalWeightKg / 0.45359237).round().toString()
                : goalWeightKg
                    .toStringAsFixed(1)
                    .replaceAll(RegExp(r'\.0$'), '');
      }
    });
  }

  Future<void> _generateRecommendation(OnboardingProfileInput profile) async {
    final languageCode = context.read<SettingsProvider>().languageCode;
    // 1. Calculate local results immediately for instant UI feedback
    final localResult = _service.computeBasePlan(
      profile,
      languageCode: languageCode,
    );

    if (!mounted) return;
    setState(() {
      _recommendation = localResult;
      _isLoadingResult = false; // Transition to Result view immediately
    });

    // 2. Load AI-enhanced layer in the background
    try {
      final aiRecommendation = await _service.buildRecommendation(
        profile,
        languageCode: languageCode,
      );
      if (!mounted) return;

      // Update with AI insights if they differ (they will have better text)
      setState(() {
        _recommendation = aiRecommendation;
      });
    } catch (e) {
      debugPrint('OnboardingScreen: AI enhancement failed (using local): $e');
      // We already have the local result shown, so no need to error out
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    HapticFeedback.heavyImpact();

    final settings = context.read<SettingsProvider>();
    final metrics = context.read<MetricsProvider>();

    try {
      // We must await both completeOnboarding and logWeight. Awaiting completeOnboarding
      // ensures settings.onboardingComplete is true before we call context.go('/')
      // to avoid GoRouter's redirect logic forcing us back to /onboarding.
      await settings.completeOnboarding(
        profile: _profile!,
        recommendation: _recommendation!,
      );
      await metrics.logWeight(_profile!.currentWeightKg);
    } catch (e) {
      debugPrint('OnboardingScreen: Error completing onboarding: $e');
    }

    // Give a tiny moment for haptics/UI state to settle then jump
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    context.go('/');
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // Animated Mesh Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) => CustomPaint(
                painter: _MeshPainter(
                  progress: _bgController.value,
                  color1: context.primaryColor,
                  color2: AppColors.tertiarySeed,
                  isDark: isDark,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    bottom: 12,
                    left: 24,
                    right: 24,
                  ),
                  child: Row(
                    children: [
                      _HeaderButton(
                        icon: LucideIcons.chevronLeft,
                        visible: _stepIndex > 0,
                        onTap: _handleBack,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProgressBar(
                              progress: (_stepIndex + 1) / _totalSteps,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n
                                  .onboarding_step(_stepIndex + 1, _totalSteps)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: context.textMutedColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Step Content
                Expanded(
                  child: _StepTransition(
                    child: Container(
                      key: ValueKey(_stepIndex),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                ),

                // Footer CTA
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    math.max(24.0, bottomPadding + 12.0),
                  ),
                  child: _PrimaryButton(
                    text: _getButtonLabel(l10n),
                    loading: _isCompleting,
                    onTap: _isLoadingResult ? () {} : _handleNext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonLabel(AppLocalizations l10n) {
    if (_stepIndex == 0) return l10n.onboarding_get_started;
    if (_stepIndex == 5) return l10n.onboarding_start_journey;
    return l10n.onboarding_continue;
  }

  Widget _buildStepContent() {
    final l10n = AppLocalizations.of(context)!;
    switch (_stepIndex) {
      case 0:
        return _buildWelcome(l10n);
      case 1:
        return _buildStep1(l10n);
      case 2:
        return _buildStep2(l10n);
      case 3:
        return _buildActivity(l10n);
      case 4:
        return _buildTimeline(l10n);
      case 5:
        return _buildResult(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcome(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'SnapCal',
          style: TextStyle(
            color: context.primaryColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.onboarding_welcome_title.toUpperCase(),
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 42,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            fontFamily: 'Syne',
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.onboarding_welcome_body,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FeaturePill(emoji: '🔥', label: l10n.onboarding_feature_target),
            _FeaturePill(emoji: '📊', label: l10n.onboarding_feature_macros),
            _FeaturePill(emoji: '✨', label: l10n.onboarding_feature_insight),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l10n.onboarding_basic_intro_eyebrow,
          title: l10n.onboarding_basic_intro_title,
          body: l10n.onboarding_basic_intro_body,
        ),
        const SizedBox(height: 18),
        _InputLabel(l10n.onboarding_age),
        _NumberInput(
          controller: _ageController,
          unit: l10n.onboarding_age_suffix,
          focusNode: _ageFocusNode,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            if (!_isImperial) {
              _heightCmFocusNode.requestFocus();
            } else {
              _heightFtFocusNode.requestFocus();
            }
          },
        ),
        const SizedBox(height: 12),
        _InputLabel(l10n.onboarding_gender),
        Row(
          children: [
            Expanded(
              child: _ChoiceCard(
                label: l10n.onboarding_male,
                emoji: '♂️',
                selected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceCard(
                label: l10n.onboarding_female,
                emoji: '♀️',
                selected: _gender == 'female',
                onTap: () => setState(() => _gender = 'female'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _InputLabel(l10n.onboarding_height),
            _UnitToggle(
              isImperial: _isImperial,
              leftLabel: 'CM',
              rightLabel: 'FT/IN',
              onChanged: _toggleMeasurementSystem,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (!_isImperial)
          _NumberInput(
            controller: _heightCmController,
            unit: 'cm',
            focusNode: _heightCmFocusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleNext(),
          )
        else
          Row(
            children: [
              Expanded(
                child: _InputBox(
                  controller: _heightFtController,
                  suffix: 'ft',
                  focusNode: _heightFtFocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _heightInFocusNode.requestFocus(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputBox(
                  controller: _heightInController,
                  suffix: 'in',
                  focusNode: _heightInFocusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleNext(),
                ),
              ),
            ],
          ),
        _ErrorMessage(message: _errorText),
      ],
    );
  }

  Widget _buildStep2(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l10n.onboarding_weight_intro_eyebrow,
          title: l10n.onboarding_weight_intro_title,
          body: l10n.onboarding_weight_intro_body,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _InputLabel(l10n.settings_current_weight),
            _UnitToggle(
              isImperial: _isImperial,
              leftLabel: 'KG',
              rightLabel: 'LBS',
              onChanged: _toggleMeasurementSystem,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _NumberInput(
          controller: _currentWeightController,
          unit: _isImperial ? 'lbs' : 'kg',
          focusNode: _currentWeightFocusNode,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _goalWeightFocusNode.requestFocus(),
        ),
        const SizedBox(height: 12),
        _InputLabel(l10n.settings_target_weight),
        _NumberInput(
          controller: _goalWeightController,
          unit: _isImperial ? 'lbs' : 'kg',
          isAccent: true,
          focusNode: _goalWeightFocusNode,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleNext(),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            l10n.onboarding_target_intro_body,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _ErrorMessage(message: _errorText),
      ],
    );
  }

  Widget _buildTimeline(AppLocalizations l10n) {
    final primaryColor = context.primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l10n.onboarding_target_intro_eyebrow,
          title: l10n.onboarding_timeline,
          body: l10n.onboarding_target_intro_body,
        ),
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              Text(
                _timelineMonths.round().toString(),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  fontFamily: 'Syne',
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n
                    .onboarding_months(_timelineMonths.round())
                    .split(' ')
                    .last
                    .toUpperCase(),
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: primaryColor,
            inactiveTrackColor: primaryColor.withValues(alpha: 0.15),
            thumbColor: primaryColor,
            overlayColor: primaryColor.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: _timelineMonths,
            min: 1,
            max: 12,
            divisions: 11,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _timelineMonths = v);
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 ${l10n.onboarding_months(1).split(' ').last.toUpperCase()}',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '12 ${l10n.onboarding_months(12).split(' ').last.toUpperCase()}',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivity(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l10n.onboarding_activity_eyebrow,
          title: l10n.onboarding_activity_title,
          body: l10n.onboarding_activity_body,
        ),
        const SizedBox(height: 18),
        _ActivityCard(
          value: 'desk_life',
          emoji: '🪑',
          title: l10n.onboarding_activity_desk_life,
          subtitle: l10n.onboarding_activity_desk_life_desc,
          color: const Color(0xFF7C8796),
          selected: _activityLevel == 'desk_life',
          onTap: () => _setActivity('desk_life'),
        ),
        _ActivityCard(
          value: 'light_mover',
          emoji: '🚶',
          title: l10n.onboarding_activity_light_mover,
          subtitle: l10n.onboarding_activity_light_mover_desc,
          color: context.primaryColor,
          selected: _activityLevel == 'light_mover',
          onTap: () => _setActivity('light_mover'),
        ),
        _ActivityCard(
          value: 'active',
          emoji: '🏃',
          title: l10n.onboarding_activity_active_title,
          subtitle: l10n.onboarding_activity_active_desc,
          color: AppColors.tertiarySeed,
          selected: _activityLevel == 'active',
          onTap: () => _setActivity('active'),
        ),
        _ActivityCard(
          value: 'athlete',
          emoji: '🏋️',
          title: l10n.onboarding_activity_athlete,
          subtitle: l10n.onboarding_activity_athlete_desc,
          color: AppColors.amber,
          selected: _activityLevel == 'athlete',
          onTap: () => _setActivity('athlete'),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            l10n.onboarding_activity_footer,
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _setActivity(String val) {
    HapticFeedback.selectionClick();
    setState(() => _activityLevel = val);
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted && _stepIndex == 3) _handleNext();
    });
  }

  Widget _buildResult(AppLocalizations l10n) {
    if (_isLoadingResult) {
      return _buildLoadingResult(l10n);
    }

    final res = _recommendation;
    if (res == null) return const SizedBox.shrink();
    final primaryColor = context.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          eyebrow: l10n.onboarding_result_success_eyebrow,
          title: l10n.onboarding_result_success_title,
          body: l10n.onboarding_result_success_body,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  res.dailyCalories.toString(),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Syne',
                    height: 0.9,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.onboarding_result_daily_calories,
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _isImperial
                      ? '📈 ~${(res.weeklyRateKg / 0.45359237).toStringAsFixed(1)} lbs / week'
                      : '📈 ~${res.weeklyRateKg.toStringAsFixed(1)} kg / week',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MacroBox(
                label: l10n.result_protein,
                value: '${res.proteinGrams}g',
                colors: AppColors.proteinGradient.colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MacroBox(
                label: l10n.result_carbs,
                value: '${res.carbGrams}g',
                colors: AppColors.carbsGradient.colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MacroBox(
                label: l10n.result_fat,
                value: '${res.fatGrams}g',
                colors: AppColors.fatGradient.colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ResultInfoCard(
          title: l10n.onboarding_result_strategy,
          body: res.insight,
        ),
        const SizedBox(height: 8),
        _ResultInfoCard(
          title: l10n.onboarding_result_recommendation,
          body: res.tip,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLoadingResult(AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            l10n.onboarding_result_loading_eyebrow.toUpperCase(),
            style: TextStyle(
              color: context.primaryColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboarding_result_calibrating,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              fontFamily: 'Syne',
              height: 1.1,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboarding_welcome_body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          const _LoadingOrb(),
          const SizedBox(height: 32),
          const _DotRunner(),
          const SizedBox(height: 20),
          Text(
            l10n.onboarding_result_calibrating,
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Internal Helper Widgets ---

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.visible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Icon(icon, size: 20, color: context.textPrimaryColor),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool loading;

  const _PrimaryButton({
    required this.text,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String emoji;
  final String label;
  const _FeaturePill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        border: Border.all(color: context.cardBorderColor),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  const _StepHeader({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            color: context.primaryColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            fontFamily: 'Syne',
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: isDark ? 0.12 : 0.08)
              : context.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? primaryColor : context.cardBorderColor,
            width: selected ? 2.0 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 20,
                    offset: Offset.zero,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? primaryColor.withValues(alpha: 0.18)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? primaryColor : context.textPrimaryColor,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final bool isImperial;
  final ValueChanged<bool> onChanged;
  final String leftLabel;
  final String rightLabel;

  const _UnitToggle({
    required this.isImperial,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleBtn(
              label: leftLabel,
              active: !isImperial,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ToggleBtn(
              label: rightLabel,
              active: isImperial,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : context.textMutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberInput extends StatefulWidget {
  final TextEditingController controller;
  final String unit;
  final bool isAccent;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool autofocus;

  const _NumberInput({
    required this.controller,
    this.unit = '',
    this.isAccent = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
    _isFocused = _effectiveFocusNode.hasFocus;
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  void didUpdateWidget(covariant _NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
      _isFocused = _effectiveFocusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;

    final bgColor = widget.isAccent
        ? (_isFocused ? primaryColor.withValues(alpha: 0.18) : primaryColor.withValues(alpha: 0.08))
        : (_isFocused ? primaryColor.withValues(alpha: 0.1) : context.cardColor);

    final borderColor = widget.isAccent
        ? primaryColor.withValues(alpha: 0.4)
        : (_isFocused ? primaryColor : context.cardBorderColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFocused ? primaryColor : borderColor,
          width: _isFocused ? 1.6 : 1.2,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.1 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _effectiveFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              autofocus: widget.autofocus,
              cursorColor: primaryColor,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: context.textPrimaryColor,
                fontFamily: 'Syne',
                letterSpacing: -1.5,
              ),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  color: context.textMutedColor.withValues(alpha: 0.25),
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.unit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                widget.unit,
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputBox extends StatefulWidget {
  final TextEditingController controller;
  final String suffix;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const _InputBox({
    required this.controller,
    required this.suffix,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<_InputBox> createState() => _InputBoxState();
}

class _InputBoxState extends State<_InputBox> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
    _isFocused = _effectiveFocusNode.hasFocus;
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  void didUpdateWidget(covariant _InputBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
      _isFocused = _effectiveFocusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: _isFocused ? primaryColor.withValues(alpha: 0.08) : context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? primaryColor : context.cardBorderColor,
          width: _isFocused ? 1.6 : 1.2,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _effectiveFocusNode,
        keyboardType: TextInputType.number,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autofocus: false,
        cursorColor: primaryColor,
        style: TextStyle(
          color: context.textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          fontFamily: 'Syne',
        ),
        decoration: InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          suffixText: widget.suffix,
          suffixStyle: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: context.textMutedColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String value;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.value,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCardBg = color.withValues(alpha: isDark ? 0.15 : 0.08);
    final activeBorderColor = color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutQuint,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? activeCardBg : context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? activeBorderColor : context.cardBorderColor,
            width: selected ? 2.0 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 20,
                    offset: Offset.zero,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.2)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? (isDark ? Colors.white : context.textPrimaryColor) : context.textPrimaryColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: selected
                          ? (isDark ? Colors.white.withValues(alpha: 0.7) : context.textSecondaryColor)
                          : context.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: selected ? color : context.textMutedColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTransition extends StatelessWidget {
  final Widget child;
  const _StepTransition({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeInQuart,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.03, 0.015),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: child,
    );
  }
}

class _MacroBox extends StatelessWidget {
  final String label;
  final String value;
  final List<Color> colors;
  const _MacroBox({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'Syne',
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultInfoCard extends StatelessWidget {
  final String title;
  final String body;
  const _ResultInfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: context.primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String? message;
  const _ErrorMessage({this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Text(
          message!,
          style: const TextStyle(
            color: AppColors.error,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;
  final bool isDark;
  _MeshPainter({
    required this.progress,
    required this.color1,
    required this.color2,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Indigo blob top-left
    final c1 = Offset(
      size.width * 0.25 + math.sin(progress * 2 * math.pi) * 30,
      size.height * 0.2 + math.cos(progress * 2 * math.pi) * 20,
    );
    canvas.drawCircle(
      c1,
      size.width * 0.6,
      paint..color = color1.withValues(alpha: isDark ? 0.08 : 0.05),
    );

    // Fuchsia blob bottom-right
    final c2 = Offset(
      size.width * 0.8 + math.cos(progress * 2 * math.pi) * 40,
      size.height * 0.8 + math.sin(progress * 2 * math.pi) * 30,
    );
    canvas.drawCircle(
      c2,
      size.width * 0.5,
      paint..color = color2.withValues(alpha: isDark ? 0.06 : 0.04),
    );
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color1 != color1 ||
      oldDelegate.color2 != color2 ||
      oldDelegate.isDark != isDark;
}

class _LoadingOrb extends StatefulWidget {
  const _LoadingOrb();
  @override
  State<_LoadingOrb> createState() => _LoadingOrbState();
}

class _LoadingOrbState extends State<_LoadingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;
    return AnimatedBuilder(
      animation: _ctrl,
      builder:
          (context, _) => Container(
            width: 100,
            height: 100,
            transform: Matrix4.diagonal3Values(
              1.0 + _ctrl.value * 0.15,
              1.0 + _ctrl.value * 0.15,
              1.0,
            ),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 44)),
            ),
          ),
    );
  }
}

class _DotRunner extends StatefulWidget {
  const _DotRunner();
  @override
  State<_DotRunner> createState() => _DotRunnerState();
}

class _DotRunnerState extends State<_DotRunner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final p = (_ctrl.value + (i * 0.2)) % 1.0;
            final opacity = math.sin(p * math.pi).clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      ),
    );
  }
}
