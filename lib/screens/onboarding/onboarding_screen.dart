import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/calorie_onboarding_service.dart';
import '../../core/utils/responsive_utils.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/settings_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const int _totalScreens = 6;
  
  late final AnimationController _entranceController;
  late final List<Animation<double>> _itemAnims;

  late final AnimationController _backgroundController;
  late final AnimationController _pulseController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightCmController;
  late final TextEditingController _heightFtController;
  late final TextEditingController _heightInController;
  late final TextEditingController _currentWeightController;
  late final TextEditingController _goalWeightController;

  final CalorieOnboardingService _service = CalorieOnboardingService();

  int _stepIndex = 0;
  bool _isImperial = false;
  String _gender = 'male';
  String _activityLevel = 'active';
  double _timelineMonths = 4;
  bool _isLoadingResult = false;
  bool _isCompleting = false;
  String? _errorText;
  Timer? _autoAdvanceTimer;
  OnboardingRecommendation? _recommendation;
  OnboardingProfileInput? _profile;

  @override
  void initState() {
    super.initState();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _isImperial = _usesImperial(locale.countryCode);

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _itemAnims = List.generate(5, (index) {
      final start = index * 0.1;
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, (start + 0.4).clamp(0, 1.0), curve: Curves.easeOut),
      );
    });

    _entranceController.forward();

    _ageController = TextEditingController(text: '28');
    _heightCmController = TextEditingController(text: '170');
    _heightFtController = TextEditingController(text: '5');
    _heightInController = TextEditingController(text: '7');
    _currentWeightController = TextEditingController(
      text: _isImperial ? '170' : '77',
    );
    _goalWeightController = TextEditingController(
      text: _isImperial ? '154' : '70',
    );
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _backgroundController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    _ageController.dispose();
    _heightCmController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  bool _usesImperial(String? countryCode) {
    return countryCode == 'US' || countryCode == 'LR' || countryCode == 'MM';
  }

  Future<void> _handleNext() async {
    HapticFeedback.selectionClick();
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
      await _generateRecommendation(profile);
      return;
    }

    if (_stepIndex == 5) {
      await _finishOnboarding();
      return;
    }

    if (!_validateCurrentStep()) return;
    setState(() {
      _errorText = null;
      _stepIndex += 1;
    });
    _entranceController.reset();
    _entranceController.forward();
  }

  void _handleBack() {
    if (_stepIndex == 0) return;
    _autoAdvanceTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() {
      _errorText = null;
      _stepIndex -= 1;
    });
    _entranceController.reset();
    _entranceController.forward();
  }

  bool _validateCurrentStep() {
    switch (_stepIndex) {
      case 0:
        return true;
      case 1:
      case 2:
      case 3:
      case 4:
        return _validateAndBuildProfile(upToStep: _stepIndex) != null;
      default:
        return true;
    }
  }

  OnboardingProfileInput? _validateAndBuildProfile({int? upToStep}) {
    final step = upToStep ?? 4;

    final age = int.tryParse(_ageController.text.trim());
    if (step >= 1 && (age == null || age < 13 || age > 100)) {
      _setError('Enter an age between 13 and 100.');
      return null;
    }

    final heightCm = _parseHeightCm();
    if (step >= 1 && (heightCm == null || heightCm < 100 || heightCm > 250)) {
      _setError('Enter a realistic height so we can calculate accurately.');
      return null;
    }

    final currentWeightKg = _parseWeightKg(_currentWeightController.text);
    if (step >= 2 &&
        (currentWeightKg == null ||
            currentWeightKg < 30 ||
            currentWeightKg > 350)) {
      _setError('Enter a realistic current weight.');
      return null;
    }

    final goalWeightKg = _parseWeightKg(_goalWeightController.text);
    if (step >= 3 &&
        (goalWeightKg == null || goalWeightKg < 30 || goalWeightKg > 350)) {
      _setError('Enter a realistic goal weight.');
      return null;
    }

    if (step >= 3 && currentWeightKg != null && goalWeightKg != null) {
      final rawWeeklyRate = _rawWeeklyRateKg(
        currentWeightKg: currentWeightKg,
        goalWeightKg: goalWeightKg,
        months: _timelineMonths.round(),
      );
      if (rawWeeklyRate.isNaN || rawWeeklyRate.isInfinite) {
        _setError('Adjust your timeline so we can build a valid plan.');
        return null;
      }
    }

    _errorText = null;
    return OnboardingProfileInput(
      age: age!,
      gender: _gender,
      heightCm: heightCm!,
      currentWeightKg: currentWeightKg ?? 0,
      goalWeightKg: goalWeightKg ?? currentWeightKg ?? 0,
      timelineMonths: _timelineMonths.round(),
      activityLevel: _activityLevel,
      weightUnit: _isImperial ? 'lb' : 'kg',
      heightUnit: _isImperial ? 'ft_in' : 'cm',
    );
  }

  void _setError(String text) {
    setState(() => _errorText = text);
  }

  double? _parseHeightCm() {
    if (!_isImperial) {
      return double.tryParse(_heightCmController.text.trim());
    }

    final feet = int.tryParse(_heightFtController.text.trim());
    final inches = int.tryParse(_heightInController.text.trim());
    if (feet == null || inches == null || feet < 3 || feet > 8) {
      return null;
    }
    if (inches < 0 || inches > 11) return null;
    return ((feet * 12) + inches) * 2.54;
  }

  double? _parseWeightKg(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return null;
    if (_isImperial) return parsed * 0.45359237;
    return parsed;
  }

  double _rawWeeklyRateKg({
    required double currentWeightKg,
    required double goalWeightKg,
    required int months,
  }) {
    final days = (months * 30.4375).clamp(30, 366);
    return (currentWeightKg - goalWeightKg).abs() / (days / 7);
  }

  void _toggleMeasurementSystem(bool toImperial) {
    if (_isImperial == toImperial) return;

    final currentHeightCm = _parseHeightCm();
    final currentWeightKg = _parseWeightKg(_currentWeightController.text);
    final goalWeightKg = _parseWeightKg(_goalWeightController.text);

    setState(() {
      _isImperial = toImperial;

      if (currentHeightCm != null) {
        if (toImperial) {
          final totalInches = currentHeightCm / 2.54;
          var feet = totalInches ~/ 12;
          var inches = (totalInches - (feet * 12)).round();
          if (inches == 12) {
            feet += 1;
            inches = 0;
          }
          _heightFtController.text = feet.toString();
          _heightInController.text = inches.toString();
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
    try {
      final recommendation = await _service.buildRecommendation(profile);
      if (!mounted) return;
      setState(() {
        _recommendation = recommendation;
        _isLoadingResult = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recommendation = null;
        _isLoadingResult = false;
        _errorText = 'We could not build your plan. Please try again.';
      });
    }
  }

  Future<void> _finishOnboarding() async {
    final recommendation = _recommendation;
    final profile = _profile;
    if (recommendation == null || profile == null || _isCompleting) return;

    setState(() => _isCompleting = true);

    final settings = context.read<SettingsProvider>();
    final metrics = context.read<MetricsProvider>();

    await settings.completeOnboarding(
      profile: profile,
      recommendation: recommendation,
    );
    await metrics.logWeight(profile.currentWeightKg);

    if (!mounted) return;
    context.go('/');
  }

  void _setActivityLevel(String value) {
    _autoAdvanceTimer?.cancel();
    HapticFeedback.lightImpact();
    setState(() => _activityLevel = value);
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _stepIndex == 4) {
        _handleNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgTop = colorScheme.surface;
    final bgBottom = colorScheme.surfaceContainer;
    final card = colorScheme.surfaceContainerHigh.withValues(alpha: 0.95);
    final border = colorScheme.outlineVariant;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, _) {
              final shift =
                  (math.sin(_backgroundController.value * math.pi * 2) + 1) / 2;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(bgTop, bgBottom, shift * 0.2)!,
                      Color.lerp(bgBottom, bgTop, shift * 0.35)!,
                      bgTop,
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _OnboardingGlowPainter(
                  progress: _backgroundController.value,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      _TopButton(
                        icon: LucideIcons.chevronLeft,
                        enabled: _stepIndex > 0,
                        onTap: _handleBack,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (_stepIndex + 1) / _totalScreens,
                                minHeight: 8,
                                backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'STEP ${_stepIndex + 1} OF $_totalScreens',
                              style: AppTypography.labelSmall.copyWith(
                                color: textSecondary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Responsive.maxWidth(context) ?? double.infinity,
                          ),
                          child: Container(
                            key: ValueKey(_stepIndex),
                            padding: EdgeInsets.all(Responsive.size(context) == ScreenSize.small ? 20 : 32),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(color: border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: _buildStepContent(textPrimary, textSecondary),
                          ),
                        ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _PrimaryButton(
                    label: _getStepButtonLabel(),
                    loading: _isCompleting,
                    onPressed: _isLoadingResult ? () {} : _handleNext,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepButtonLabel() {
    if (_stepIndex == 0) return 'Get Started';
    if (_stepIndex == 5) return 'Start My Journey';
    return 'Continue';
  }

  Widget _buildStepContent(Color textPrimary, Color textSecondary) {
    switch (_stepIndex) {
      case 0:
        return _buildWelcome(textPrimary, textSecondary);
      case 1:
        return _buildBasicInfo(textPrimary, textSecondary);
      case 2:
        return _buildCurrentWeight(textPrimary, textSecondary);
      case 3:
        return _buildGoalTimeline(textPrimary, textSecondary);
      case 4:
        return _buildActivity(textPrimary, textSecondary);
      case 5:
        return _buildResult(textPrimary, textSecondary);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcome(Color textPrimary, Color textSecondary) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredSlide(
          _itemAnims[0],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'SNAPCAL',
                  style: AppTypography.labelMedium.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _staggeredSlide(
          _itemAnims[1],
          Text(
            'Your goal.\nYour calories.\nYour pace.',
            style: AppTypography.displayMedium.copyWith(
              color: textPrimary,
              height: 1.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _staggeredSlide(
          _itemAnims[2],
          Text(
            'Answer a few quick questions to set your personalized daily calorie target.',
            style: AppTypography.bodyLarge.copyWith(
              color: textSecondary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        _staggeredSlide(_itemAnims[3], const _FeatureStrip()),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBasicInfo(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredSlide(
          _itemAnims[0],
          const _SectionIntro(
            eyebrow: 'PERSONAL DETAILS',
            title: 'Set your baseline metrics.',
            body: 'We use these to calculate your resting metabolic rate (RMR).',
          ),
        ),
        const SizedBox(height: 32),
        _staggeredSlide(
          _itemAnims[1],
          _LabeledField(
            label: 'Age',
            child: _NumberInput(
              controller: _ageController,
              suffix: 'years',
              hint: '28',
            ),
          ),
        ),
        const SizedBox(height: 24),
        _staggeredSlide(
          _itemAnims[2],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gender',
                style: AppTypography.titleMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceChipCard(
                      label: 'Male',
                      icon: LucideIcons.user,
                      selected: _gender == 'male',
                      onTap: () => setState(() => _gender = 'male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceChipCard(
                      label: 'Female',
                      icon: LucideIcons.user,
                      selected: _gender == 'female',
                      onTap: () => setState(() => _gender = 'female'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _staggeredSlide(
          _itemAnims[3],
          Column(
            children: [
              Row(
                children: [
                  Text(
                    'Height',
                    style: AppTypography.titleMedium.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _UnitToggle(
                    leftLabel: 'cm',
                    rightLabel: 'ft/in',
                    isRightSelected: _isImperial,
                    onChanged: _toggleMeasurementSystem,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isImperial
                  ? Row(
                      children: [
                        Expanded(
                          child: _NumberInput(
                            controller: _heightFtController,
                            suffix: 'ft',
                            hint: '5',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NumberInput(
                            controller: _heightInController,
                            suffix: 'in',
                            hint: '7',
                          ),
                        ),
                      ],
                    )
                  : _NumberInput(
                      controller: _heightCmController,
                      suffix: 'cm',
                      hint: '170',
                    ),
            ],
          ),
        ),
        _ErrorText(message: _errorText),
      ],
    );
  }

  Widget _buildCurrentWeight(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredSlide(
          _itemAnims[0],
          const _SectionIntro(
            eyebrow: 'CURRENT STATUS',
            title: 'What do you weigh today?',
            body: 'This helps us understand your starting point.',
          ),
        ),
        const SizedBox(height: 48),
        _staggeredSlide(
          _itemAnims[1],
          _LargeNumberField(
            controller: _currentWeightController,
            suffix: _isImperial ? 'lb' : 'kg',
          ),
        ),
        const SizedBox(height: 24),
        _staggeredSlide(
          _itemAnims[2],
          Text(
            'No judgment. Every journey starts with an honest metric.',
            style: AppTypography.bodyMedium.copyWith(
              color: textSecondary,
            ),
          ),
        ),
        _ErrorText(message: _errorText),
      ],
    );
  }

  Widget _buildGoalTimeline(Color textPrimary, Color textSecondary) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentWeightKg = _parseWeightKg(_currentWeightController.text);
    final goalWeightKg = _parseWeightKg(_goalWeightController.text);
    
    final isMaintenance = currentWeightKg != null && goalWeightKg != null && 
        (currentWeightKg - goalWeightKg).abs() < 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredSlide(
          _itemAnims[0],
          _SectionIntro(
            eyebrow: 'THE TARGET',
            title: isMaintenance ? 'Maintain your weight' : 'What is your goal weight?',
            body: isMaintenance 
                ? 'We will build a plan to keep your weight stable while hitting your macros.'
                : 'We will structure your calories to hit this target within your timeline.',
          ),
        ),
        const SizedBox(height: 32),
        _staggeredSlide(
          _itemAnims[1],
          _LargeNumberField(
            controller: _goalWeightController,
            suffix: _isImperial ? 'lb' : 'kg',
          ),
        ),
        if (!isMaintenance) ...[
          const SizedBox(height: 40),
          _staggeredSlide(
            _itemAnims[2],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Timeline',
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: colorScheme.primary,
                    inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.1),
                    thumbColor: colorScheme.primary,
                    overlayColor: colorScheme.primary.withValues(alpha: 0.1),
                    trackHeight: 10,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                  ),
                  child: Slider(
                    min: 1,
                    max: 12,
                    divisions: 11,
                    value: _timelineMonths,
                    onChanged: (value) => setState(() => _timelineMonths = value),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_timelineMonths.round()} Month${_timelineMonths.round() == 1 ? '' : 's'}',
                    style: AppTypography.headlineSmall.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        _ErrorText(message: _errorText),
      ],
    );
  }

  Widget _buildActivity(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredSlide(
          _itemAnims[0],
          const _SectionIntro(
            eyebrow: 'Activity',
            title: 'How active does your week look?',
            body:
                'Choose the pattern that matches most weeks. You can change it later.',
          ),
        ),
        const SizedBox(height: 20),
        _staggeredSlide(
          _itemAnims[1],
          Column(
            children: _activityCards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ActivityCard(
                      item: card,
                      selected: _activityLevel == card.value,
                      onTap: () => _setActivityLevel(card.value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _staggeredSlide(
          _itemAnims[2],
          Text(
            'Active is selected by default. Tap once and we will keep moving.',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(Color textPrimary, Color textSecondary) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoadingResult) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionIntro(
            eyebrow: 'AI Result',
            title: 'Building your calorie target.',
            body:
                'We are combining your baseline, activity, and goal pace into a plan that is ready to use.',
          ),
          const SizedBox(height: 28),
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final scale = 0.92 + (_pulseController.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.24),
                          const Color(0xFFFFA44B).withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.flame,
                      color: AppColors.primary,
                      size: 62,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Calibrating your daily target...',
              style: TextStyle(
                color: textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final recommendation = _recommendation;
    if (recommendation == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionIntro(
            eyebrow: 'CALCULATION ERROR',
            title: 'We could not finish your plan.',
            body:
                'Try the last step again or adjust your inputs.',
          ),
          _ErrorText(message: _errorText),
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Try Again', onPressed: _handleBack),
        ],
      );
    }

    final weeklyText =
        recommendation.goalMode == 'maintain'
            ? 'Maintain Current Weight'
            : '~${recommendation.weeklyRateKg.toStringAsFixed(1)} kg / week';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredSlide(
          _itemAnims[0],
          const _SectionIntro(
            eyebrow: 'AI CALIBRATION COMPLETE',
            title: 'Daily target is ready.',
            body: 'This number is personalized for your body and target pace.',
          ),
        ),
        if (recommendation.isMinor) ...[
          const SizedBox(height: 12),
          const _SoftWarning(
            text:
                'Minor detection. Please consult a professional before starting any calorie restriction.',
          ),
        ],
        if (recommendation.safetyNote.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SoftWarning(text: recommendation.safetyNote),
        ],
        const SizedBox(height: 32),
        _staggeredSlide(
          _itemAnims[1],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${recommendation.dailyCalories}',
                  style: AppTypography.displayLarge.copyWith(
                    color: colorScheme.primary,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3,
                    fontSize: AppTypography.displayLarge.fontSize! * Responsive.fontScale(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'DAILY CALORIES',
                  style: AppTypography.labelLarge.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(LucideIcons.trendingUp, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      weeklyText,
                      style: AppTypography.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _staggeredSlide(
          _itemAnims[2],
          Row(
            children: [
              Expanded(
                child: _MacroTile(
                  label: 'Protein',
                  value: '${recommendation.proteinGrams}g',
                  color: const Color(0xFF64B5F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroTile(
                  label: 'Carbs',
                  value: '${recommendation.carbGrams}g',
                  color: const Color(0xFF81C784),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroTile(
                  label: 'Fats',
                  value: '${recommendation.fatGrams}g',
                  color: const Color(0xFFFFD54F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _staggeredSlide(
          _itemAnims[3],
          Column(
            children: [
              _InsightCard(title: 'Strategy', body: recommendation.insight),
              const SizedBox(height: 12),
              _InsightCard(title: 'Recommendation', body: recommendation.tip),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SectionIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;

  const _SectionIntro({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: AppTypography.bodyLarge.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TopButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _TopButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ScaleTap(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: enabled ? 0.12 : 0.06)
                  : Colors.white.withValues(alpha: enabled ? 0.72 : 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.dividerColor),
        ),
        child: Icon(
          icon,
          size: 20,
          color:
              enabled
                  ? context.textPrimaryColor
                  : context.textMutedColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _ScaleTap(
      onTap: loading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTypography.titleMedium.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      LucideIcons.arrowRight,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ScaleTap({required this.child, this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _controller.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

Widget _staggeredSlide(Animation<double> animation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - animation.value)),
          child: child,
        ),
      );
    },
    child: child,
  );
}



class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _FeaturePill(icon: LucideIcons.flame, label: 'Personal calorie target'),
        _FeaturePill(icon: LucideIcons.pieChart, label: 'Macro split'),
        _FeaturePill(icon: LucideIcons.sparkles, label: 'AI insight'),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  final String hint;

  const _NumberInput({
    required this.controller,
    required this.suffix,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: context.cardSoftColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }
}

class _LargeNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;

  const _LargeNumberField({required this.controller, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardSoftColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.8,
                color: context.textPrimaryColor,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
              ),
            ),
          ),
          Text(
            suffix,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChipCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChipCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : context.cardSoftColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : Colors.grey,
              size: 18,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool isRightSelected;
  final ValueChanged<bool> onChanged;

  const _UnitToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isRightSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardSoftColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitOption(
            label: leftLabel,
            selected: !isRightSelected,
            onTap: () => onChanged(false),
          ),
          _UnitOption(
            label: rightLabel,
            selected: isRightSelected,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _UnitOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}



class _SoftWarning extends StatelessWidget {
  final String text;

  const _SoftWarning({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.shieldAlert,
            size: 20,
            color: colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.labelMedium.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String? message;

  const _ErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message!,
        style: const TextStyle(
          color: Color(0xFFD93B3B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              selected
                  ? item.color.withValues(alpha: 0.14)
                  : context.cardSoftColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                selected
                    ? item.color.withValues(alpha: 0.5)
                    : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: selected ? item.color : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String body;

  const _InsightCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingGlowPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OnboardingGlowPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      final dx = (size.width / 7) * i;
      final dy = 120 + (math.sin(progress * math.pi * 2 + i) * 18);
      paint.color = color.withValues(alpha: 0.04);
      canvas.drawCircle(Offset(dx, dy), 42, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ActivityItem {
  final String value;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityItem({
    required this.value,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

const List<_ActivityItem> _activityCards = [
  _ActivityItem(
    value: 'desk_life',
    emoji: '🪑',
    title: 'Desk Life',
    subtitle: 'Little to no exercise',
    color: Color(0xFF7C8796),
  ),
  _ActivityItem(
    value: 'light_mover',
    emoji: '🚶',
    title: 'Light Mover',
    subtitle: '1-3 days/week',
    color: Color(0xFF25A870),
  ),
  _ActivityItem(
    value: 'active',
    emoji: '🏃',
    title: 'Active',
    subtitle: '3-5 days/week',
    color: Color(0xFF6750A4), // M3 Royal Purple
  ),
  _ActivityItem(
    value: 'athlete',
    emoji: '🏋️',
    title: 'Athlete',
    subtitle: '6-7 days/week',
    color: Color(0xFFFF8B1F),
  ),
];
