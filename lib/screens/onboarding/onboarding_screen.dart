import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

/// ============================================================================
/// PREMIUM ONBOARDING SCREEN - CALORIE GOAL SETUP
/// ============================================================================
/// A beautiful first-launch screen where the user sets their daily calorie goal.
/// Features:
/// - Animated gradient background with floating particles
/// - Smart preset cards (Lose Weight, Maintain, Build Muscle)
/// - Custom slider for fine-tuning
/// - Live-updating calorie display with animation
/// - Premium glassmorphism aesthetic
/// ============================================================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _presetsFade;
  late Animation<double> _sliderFade;
  late Animation<double> _ctaFade;

  // State
  int _selectedCalories = 2000;
  int _selectedPresetIndex = 1; // Default: Maintain
  bool _isSaving = false;

  // Presets
  static const _presets = [
    _GoalPreset(
      title: 'Lose Weight',
      subtitle: 'Calorie deficit for healthy fat loss',
      icon: LucideIcons.trendingDown,
      calories: 1500,
      color: Color(0xFFFF6B6B),
      gradient: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
    ),
    _GoalPreset(
      title: 'Maintain',
      subtitle: 'Keep your current body composition',
      icon: LucideIcons.equal,
      calories: 2000,
      color: Color(0xFF4ECDC4),
      gradient: [Color(0xFF4ECDC4), Color(0xFF2ECC71)],
    ),
    _GoalPreset(
      title: 'Build Muscle',
      subtitle: 'Calorie surplus for muscle growth',
      icon: LucideIcons.trendingUp,
      calories: 2800,
      color: Color(0xFF6C5CE7),
      gradient: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Fade-in controller for staggered animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Header: fade + slide up
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // Presets: fade in after header
    _presetsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    // Slider: fade in after presets
    _sliderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    // CTA: fade in last
    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _selectPreset(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPresetIndex = index;
      _selectedCalories = _presets[index].calories;
    });
  }

  void _onSliderChanged(double value) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCalories = value.round();
      // Deselect preset if slider doesn't match any
      _selectedPresetIndex = -1;
      for (int i = 0; i < _presets.length; i++) {
        if ((_selectedCalories - _presets[i].calories).abs() < 50) {
          _selectedPresetIndex = i;
          break;
        }
      }
    });
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    HapticFeedback.heavyImpact();
    final settings = context.read<SettingsProvider>();
    await settings.completeOnboarding(_selectedCalories);

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final bg1 = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final bg2 = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary =
        isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF64748B);
    final cardBg =
        isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.8);
    final cardBorder =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06);

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _particleController,
            builder:
                (context, _) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        bg1,
                        Color.lerp(
                          bg2,
                          bg1,
                          (math.sin(_particleController.value * math.pi * 2) +
                                  1) /
                              2,
                        )!,
                        bg1,
                      ],
                    ),
                  ),
                ),
          ),

          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder:
                (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _ParticlePainter(
                    animationValue: _particleController.value,
                    color: AppColors.primary,
                  ),
                ),
          ),

          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder:
                  (context, _) => SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: size.height * 0.06),

                        // ── Header ─────────────────────────────────────
                        SlideTransition(
                          position: _headerSlide,
                          child: Opacity(
                            opacity: _headerFade.value,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.15),
                                        AppColors.primary.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.sparkles,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Welcome to SnapCal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "What's your\ncalorie goal?",
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                    letterSpacing: -1.5,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Choose a plan or set your own daily target',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Calorie Display ────────────────────────────
                        Opacity(
                          opacity: _presetsFade.value,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                final pulse =
                                    Tween<double>(
                                      begin: 0.95,
                                      end: 1.0,
                                    ).animate(_pulseController).value;
                                return Transform.scale(
                                  scale: pulse,
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors:
                                            _selectedPresetIndex >= 0
                                                ? _presets[_selectedPresetIndex]
                                                    .gradient
                                                : [
                                                  AppColors.primary,
                                                  AppColors.primary.withOpacity(
                                                    0.7,
                                                  ),
                                                ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_selectedPresetIndex >= 0
                                                  ? _presets[_selectedPresetIndex]
                                                      .color
                                                  : AppColors.primary)
                                              .withOpacity(0.4),
                                          blurRadius: 40,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Text(
                                            '$_selectedCalories',
                                            key: ValueKey(_selectedCalories),
                                            style: const TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: -2,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          'kcal / day',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Preset Cards ───────────────────────────────
                        Opacity(
                          opacity: _presetsFade.value,
                          child: Row(
                            children: List.generate(_presets.length, (index) {
                              final preset = _presets[index];
                              final isSelected = _selectedPresetIndex == index;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : 6,
                                    right: index == 2 ? 0 : 6,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _selectPreset(index),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? preset.color.withOpacity(0.15)
                                                : cardBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? preset.color.withOpacity(
                                                    0.5,
                                                  )
                                                  : cardBorder,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow:
                                            isSelected
                                                ? [
                                                  BoxShadow(
                                                    color: preset.color
                                                        .withOpacity(0.2),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  isSelected
                                                      ? LinearGradient(
                                                        colors: preset.gradient,
                                                      )
                                                      : null,
                                              color:
                                                  isSelected
                                                      ? null
                                                      : preset.color
                                                          .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              preset.icon,
                                              size: 20,
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : preset.color,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            preset.title,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  isSelected
                                                      ? preset.color
                                                      : textPrimary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${preset.calories}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  isSelected
                                                      ? preset.color
                                                      : textPrimary.withOpacity(
                                                        0.7,
                                                      ),
                                            ),
                                          ),
                                          Text(
                                            'kcal',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Slider Section ─────────────────────────────
                        Opacity(
                          opacity: _sliderFade.value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Fine-tune your goal',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$_selectedCalories kcal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor:
                                      _selectedPresetIndex >= 0
                                          ? _presets[_selectedPresetIndex].color
                                          : AppColors.primary,
                                  inactiveTrackColor: (_selectedPresetIndex >= 0
                                          ? _presets[_selectedPresetIndex].color
                                          : AppColors.primary)
                                      .withOpacity(0.15),
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 14,
                                    elevation: 4,
                                  ),
                                  overlayColor: AppColors.primary.withOpacity(
                                    0.1,
                                  ),
                                  trackHeight: 6,
                                ),
                                child: Slider(
                                  value: _selectedCalories.toDouble(),
                                  min: 1000,
                                  max: 5000,
                                  divisions: 80, // Steps of 50
                                  onChanged: _onSliderChanged,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '1000',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '5000',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Info Card ──────────────────────────────────
                        Opacity(
                          opacity: _sliderFade.value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.info,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You can always change this later in Settings',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── CTA Button ─────────────────────────────────
                        Opacity(
                          opacity: _ctaFade.value,
                          child: SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      _selectedPresetIndex >= 0
                                          ? _presets[_selectedPresetIndex]
                                              .gradient
                                          : [
                                            AppColors.primary,
                                            AppColors.primary.withOpacity(0.8),
                                          ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_selectedPresetIndex >= 0
                                            ? _presets[_selectedPresetIndex]
                                                .color
                                            : AppColors.primary)
                                        .withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    _isSaving ? null : _completeOnboarding,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child:
                                    _isSaving
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Get Started',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              LucideIcons.arrowRight,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 32,
                        ),
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

/// Goal preset data class
class _GoalPreset {
  final String title;
  final String subtitle;
  final IconData icon;
  final int calories;
  final Color color;
  final List<Color> gradient;

  const _GoalPreset({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.calories,
    required this.color,
    required this.gradient,
  });
}

/// Floating particle painter (matches splash screen aesthetic)
class _ParticlePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _ParticlePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42); // Fixed seed for deterministic particles

    for (int i = 0; i < 15; i++) {
      final baseX = random.nextDouble();
      final baseY = random.nextDouble();
      final particleSize = random.nextDouble() * 3 + 1.5;
      final speed = random.nextDouble() * 0.4 + 0.1;
      final opacity = random.nextDouble() * 0.2 + 0.05;

      final y = (baseY + animationValue * speed) % 1.0;
      final x =
          baseX + math.sin(animationValue * math.pi * 2 + baseY * 10) * 0.02;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
