import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/premium_conversion_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/meal_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/app_icon.dart';

// ─── PREMIUM LOCKED OVERLAY ─────────────────────────────────────────────

/// Shown to non-Pro users who have hit the daily AI limit.
/// A soft glass overlay with a single, clear upgrade call-to-action.
class CoachLockedOverlay extends StatelessWidget {
  const CoachLockedOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.homeCoachAccent;

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: context.backgroundColor.withValues(
              alpha: isDark ? 0.85 : 0.78,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    accent.withValues(alpha: 0.05),
                    accent.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: _LockedCard(
            title: l10n.coach_locked_title,
            body: l10n.coach_locked_desc,
            buttonText: l10n.coach_limit_btn,
            onUpgrade: () => PremiumConversionService().openPaywall(
              context,
              PaywallEntryPoint.aiCoachLimit,
              featureName: 'ai_coach',
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedCard extends StatelessWidget {
  final String title;
  final String body;
  final String buttonText;
  final VoidCallback onUpgrade;

  const _LockedCard({
    required this.title,
    required this.body,
    required this.buttonText,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.homeCoachAccent;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(AppSymbols.sparkles, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily limit reached',
                      style: AppTypography.labelSmall.copyWith(
                        color: accent,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textSecondaryColor,
              height: 1.5,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onUpgrade,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.75)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppSymbols.sparkles,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            buttonText,
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
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

// ─── COACH PROFILE SHEET ────────────────────────────────────────────────

class CoachProfileSheet extends ConsumerStatefulWidget {
  const CoachProfileSheet({super.key});

  @override
  ConsumerState<CoachProfileSheet> createState() => _CoachProfileSheetState();
}

class _CoachProfileSheetState extends ConsumerState<CoachProfileSheet> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _targetWeight;
  late final TextEditingController _dislikes;
  late final TextEditingController _medical;

  late String _gender;
  late String _goal;
  late String _activity;
  late String _diet;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider).valueOrNull;
    _age = TextEditingController(text: s?.age?.toString() ?? '');
    _height = TextEditingController(text: s?.height?.toString() ?? '');
    _weight = TextEditingController(text: s?.startingWeight?.toString() ?? '');
    _targetWeight =
        TextEditingController(text: s?.targetWeight?.toString() ?? '');
    _dislikes = TextEditingController(text: s?.foodDislikes ?? '');
    _medical = TextEditingController(text: s?.medicalNotes ?? '');
    _gender = s?.gender ?? 'other';
    _goal = s?.goalMode ?? 'maintain';
    _activity = s?.activityLevel ?? 'moderatelyActive';
    _diet = s?.dietaryRestriction ?? 'none';
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    _dislikes.dispose();
    _medical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textMutedColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Coach profile',
                style: AppTypography.titleLarge.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Helps the AI tailor advice to you. Stored on this device only.',
                style: AppTypography.bodySmall.copyWith(
                  color: context.textSecondaryColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              _Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Age',
                      controller: _age,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Gender',
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _gender = v ?? _gender),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Height (cm)',
                      controller: _height,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(
                      label: 'Current weight (kg)',
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Target weight (kg)',
                      controller: _targetWeight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Goal',
                      value: _goal,
                      items: const [
                        DropdownMenuItem(
                          value: 'lose',
                          child: Text('Lose weight'),
                        ),
                        DropdownMenuItem(
                          value: 'gain',
                          child: Text('Gain weight'),
                        ),
                        DropdownMenuItem(
                          value: 'maintain',
                          child: Text('Maintain'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _goal = v ?? _goal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Row(
                children: [
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Activity',
                      value: _activity,
                      items: const [
                        DropdownMenuItem(
                          value: 'sedentary',
                          child: Text('Sedentary'),
                        ),
                        DropdownMenuItem(
                          value: 'lightlyActive',
                          child: Text('Lightly active'),
                        ),
                        DropdownMenuItem(
                          value: 'moderatelyActive',
                          child: Text('Moderately active'),
                        ),
                        DropdownMenuItem(
                          value: 'veryActive',
                          child: Text('Very active'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _activity = v ?? _activity),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Diet',
                      value: _diet,
                      items: const [
                        DropdownMenuItem(
                          value: 'none',
                          child: Text('No restriction'),
                        ),
                        DropdownMenuItem(
                          value: 'vegetarian',
                          child: Text('Vegetarian'),
                        ),
                        DropdownMenuItem(
                          value: 'vegan',
                          child: Text('Vegan'),
                        ),
                        DropdownMenuItem(
                          value: 'gluten-free',
                          child: Text('Gluten-free'),
                        ),
                        DropdownMenuItem(
                          value: 'keto',
                          child: Text('Keto'),
                        ),
                        DropdownMenuItem(
                          value: 'halal',
                          child: Text('Halal'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _diet = v ?? _diet),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Food dislikes (comma separated)',
                controller: _dislikes,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Medical notes (optional)',
                controller: _medical,
                maxLines: 2,
              ),
              const SizedBox(height: 22),
              _PrimaryButton(
                label: 'Save profile',
                onTap: () async {
                  final s = ref.read(settingsProvider.notifier);
                  await s.updateCoachProfile(
                    age: int.tryParse(_age.text),
                    height: double.tryParse(_height.text),
                    startingWeight: double.tryParse(_weight.text),
                    targetWeight: double.tryParse(_targetWeight.text),
                    gender: _gender,
                    goalMode: _goal,
                    activityLevel: _activity,
                    dietaryRestriction:
                        _diet == 'none' ? null : _diet,
                    foodDislikes: _dislikes.text.trim().isEmpty
                        ? null
                        : _dislikes.text.trim(),
                    medicalNotes: _medical.text.trim().isEmpty
                        ? null
                        : _medical.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Profile saved'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final List<Widget> children;
  const _Row({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: context.textMutedColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: AppTypography.bodyMedium.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.cardColor,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.homeCoachAccent.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: context.textMutedColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              icon: Icon(
                AppSymbols.chevronDown,
                size: 18,
                color: context.textMutedColor,
              ),
              isExpanded: true,
              style: AppTypography.bodyMedium.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.homeCoachAccent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.75)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── WEEKLY REPORT SHEET ────────────────────────────────────────────────

class WeeklyReportSheet extends ConsumerWidget {
  const WeeklyReportSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null || !settings.isPro) {
      PremiumConversionService().openPaywall(
        context,
        PaywallEntryPoint.reportInsight,
        featureName: 'weekly_report',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final calorieGoal =
        settings.dailyCalorieGoal > 0 ? settings.dailyCalorieGoal : 2000;
    final targetProtein =
        settings.dailyProteinGoal > 0 ? settings.dailyProteinGoal : 120;
    final targetCarbs =
        settings.dailyCarbGoal > 0 ? settings.dailyCarbGoal : 220;
    final targetFat =
        settings.dailyFatGoal > 0 ? settings.dailyFatGoal : 65;

    final bestDay = 'No data';

    final nextTarget =
        'Maintain $calorieGoal kcal/day — keep your rhythm.';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textMutedColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          AppColors.homeCoachAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AppSymbols.barChart3,
                      size: 18,
                      color: AppColors.homeCoachAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly check-in',
                          style: AppTypography.titleLarge.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'How the last 7 days went',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ReportRow(
                label: 'Daily calorie goal',
                value: '$calorieGoal kcal',
                sub: 'Set in your profile',
                color: AppColors.calories,
              ),
              _ReportRow(
                label: 'Daily protein goal',
                value: '${targetProtein}g',
                sub: 'Set in your profile',
                color: AppColors.protein,
              ),
              _ReportRow(
                label: 'Best day',
                value: bestDay,
                sub: 'Closest to goals',
                color: AppColors.vividBlue,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.homeCoachAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        AppColors.homeCoachAccent.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT TARGET',
                      style: TextStyle(
                        color: AppColors.homeCoachAccent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextTarget,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textPrimaryColor,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _ReportRow({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  sub,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textMutedColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
