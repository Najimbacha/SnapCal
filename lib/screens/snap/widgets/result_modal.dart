import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/gemini_service.dart';
import '../../../providers/settings_provider.dart';
import '../../../../widgets/ad_banner.dart';

class ResultModal extends StatefulWidget {
  final Uint8List? imageBytes;
  final NutritionResult? result;
  final Function(String name, int calories, int protein, int carbs, int fat, String? portion) onSave;
  final VoidCallback onCancel;

  const ResultModal({
    super.key,
    this.imageBytes,
    this.result,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<ResultModal> createState() => _ResultModalState();
}

class _ResultModalState extends State<ResultModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  double _multiplier = 1.0;
  late final int _baseCalories;
  late final int _baseProtein;
  late final int _baseCarbs;
  late final int _baseFat;
  String _selectedMealType = 'Lunch';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.result?.foodName ?? '');
    _caloriesController = TextEditingController(text: '${widget.result?.calories ?? 0}');
    _proteinController = TextEditingController(text: '${widget.result?.protein ?? 0}');
    _carbsController = TextEditingController(text: '${widget.result?.carbs ?? 0}');
    _fatController = TextEditingController(text: '${widget.result?.fat ?? 0}');

    _baseCalories = widget.result?.calories ?? 0;
    _baseProtein = widget.result?.protein ?? 0;
    _baseCarbs = widget.result?.carbs ?? 0;
    _baseFat = widget.result?.fat ?? 0;

    _setMealTypeByTime();
  }

  void _setMealTypeByTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) _selectedMealType = 'Breakfast';
    else if (hour < 16) _selectedMealType = 'Lunch';
    else if (hour < 21) _selectedMealType = 'Dinner';
    else _selectedMealType = 'Snack';
  }

  void _updateValues() {
    _caloriesController.text = (_baseCalories * _multiplier).round().toString();
    _proteinController.text = (_baseProtein * _multiplier).round().toString();
    _carbsController.text = (_baseCarbs * _multiplier).round().toString();
    _fatController.text = (_baseFat * _multiplier).round().toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.mediumImpact();
    widget.onSave(
      _nameController.text.trim(),
      int.tryParse(_caloriesController.text) ?? 0,
      int.tryParse(_proteinController.text) ?? 0,
      int.tryParse(_carbsController.text) ?? 0,
      int.tryParse(_fatController.text) ?? 0,
      widget.result?.portion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Immersive Background ──
          if (widget.imageBytes != null)
            Positioned(
              top: 0, left: 0, right: 0, height: 350,
              child: Stack(
                children: [
                  Image.memory(
                    widget.imageBytes!,
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            context.backgroundColor,
                          ],
                          stops: const [0, 0.4, 0.95],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Main Content ──
          Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 140),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedMealType.toUpperCase(),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _nameController.text,
                                    style: AppTypography.heading2.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 32,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _HealthCircle(score: widget.result?.healthScore ?? 7),
                          ],
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                        const SizedBox(height: 16),

                        if (widget.result?.insights.isNotEmpty ?? false)
                          Wrap(
                            spacing: 8,
                            children: widget.result!.insights.map((insight) => _InsightPill(text: insight)).toList(),
                          ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 32),

                        _CalorieSpotlight(
                          controller: _caloriesController,
                          dailyGoal: settings.dailyCalorieGoal,
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                        const SizedBox(height: 24),

                        Text(
                          'MACRONUTRIENTS',
                          style: AppTypography.labelSmall.copyWith(
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MacroCard(
                                label: 'Protein',
                                controller: _proteinController,
                                color: AppColors.protein,
                                goal: settings.dailyProteinGoal,
                                icon: LucideIcons.beef,
                                isHero: _baseProtein >= 25,
                                heroLabel: 'POWER',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MacroCard(
                                label: 'Carbs',
                                controller: _carbsController,
                                color: AppColors.carbs,
                                goal: settings.dailyCarbGoal,
                                icon: LucideIcons.wheat,
                                isHero: _baseCarbs >= 60,
                                heroLabel: 'ENERGY',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MacroCard(
                                label: 'Fat',
                                controller: _fatController,
                                color: AppColors.fat,
                                goal: settings.dailyFatGoal,
                                icon: LucideIcons.droplets,
                                isHero: _baseFat <= 8 && _baseCalories >= 200,
                                heroLabel: 'LEAN',
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        _PortionSelector(
                          multiplier: _multiplier,
                          portionText: widget.result?.portion ?? 'Standard serving',
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _multiplier = val;
                              _updateValues();
                            });
                          },
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 24),
                        const AdBanner().animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Floating Action Bar ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
                  decoration: BoxDecoration(
                    color: context.backgroundColor.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: context.textMutedColor.withValues(alpha: 0.1))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SecondaryButton(
                          label: 'Retake',
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onCancel();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _PrimaryButton(
                          label: 'Log this meal',
                          onPressed: _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCircle extends StatelessWidget {
  final int score;
  const _HealthCircle({required this.score});

  Color get color => score >= 8 ? const Color(0xFF10B981) : (score >= 5 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score',
              style: AppTypography.heading3.copyWith(color: color, fontWeight: FontWeight.w900, height: 1),
            ),
            Text(
              'HEALTH',
              style: AppTypography.labelSmall.copyWith(color: color, fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  final String text;
  const _InsightPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.textMutedColor.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(color: context.textSecondaryColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CalorieSpotlight extends StatelessWidget {
  final TextEditingController controller;
  final int dailyGoal;

  const _CalorieSpotlight({required this.controller, required this.dailyGoal});

  @override
  Widget build(BuildContext context) {
    final val = int.tryParse(controller.text) ?? 0;
    final double percent = (val / dailyGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.cardColor, context.cardColor.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.textMutedColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENERGY',
                style: AppTypography.labelSmall.copyWith(color: context.textSecondaryColor, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const Icon(LucideIcons.flame, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w900, fontSize: 64, height: 1),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'KCAL',
                style: AppTypography.titleLarge.copyWith(color: context.textSecondaryColor, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: context.textMutedColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4))),
              AnimatedContainer(
                duration: 500.ms,
                height: 8, width: (MediaQuery.of(context).size.width - 104) * percent,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This meal is ${(percent * 100).round()}% of your daily energy goal.',
            style: AppTypography.bodySmall.copyWith(color: context.textSecondaryColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final int goal;
  final IconData icon;
  final bool isHero;
  final String? heroLabel;

  const _MacroCard({
    required this.label,
    required this.controller,
    required this.color,
    required this.goal,
    required this.icon,
    this.isHero = false,
    this.heroLabel,
  });

  @override
  Widget build(BuildContext context) {
    final val = int.tryParse(controller.text) ?? 0;
    final percent = (val / goal).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHero ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.15),
              width: isHero ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 12),
              Text(
                label.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  suffixText: 'g',
                  suffixStyle: AppTypography.labelSmall.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 3,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (isHero)
          Positioned(
            top: -10,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                heroLabel ?? 'HERO',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.4)),
          ),
      ],
    );
  }
}

class _PortionSelector extends StatelessWidget {
  final double multiplier;
  final String portionText;
  final ValueChanged<double> onChanged;

  const _PortionSelector({required this.multiplier, required this.portionText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOGGING PORTION',
          style: AppTypography.labelSmall.copyWith(color: context.textSecondaryColor, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.textMutedColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(portionText, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                    Text('${(multiplier * 100).round()}% of AI estimate', style: AppTypography.bodySmall.copyWith(color: context.textSecondaryColor)),
                  ],
                ),
              ),
              _MultiplierControls(value: multiplier, onChanged: onChanged),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiplierControls extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _MultiplierControls({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _qBtn(LucideIcons.minus, () => value > 0.25 ? onChanged(value - 0.25) : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('${value.toStringAsFixed(1)}x', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary)),
          ),
          _qBtn(LucideIcons.plus, () => value < 4.0 ? onChanged(value + 0.25) : null),
        ],
      ),
    );
  }

  Widget _qBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 16, color: onTap == null ? Colors.grey : AppColors.primary)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: Text(label, style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      child: Text(label, style: AppTypography.bodyLarge.copyWith(color: context.textSecondaryColor, fontWeight: FontWeight.w700)),
    );
  }
}
