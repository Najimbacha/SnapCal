import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/meal_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/app_icon.dart';
import 'ai_orb.dart';
import 'metric_progress_strip.dart';

/// A clean welcome state — greeting, today's insight, and a row of quick prompts.
class AssistantWelcomeState extends ConsumerWidget {
  final ValueChanged<String> onQuickPrompt;
  final ValueChanged<String> onSuggestion;

  const AssistantWelcomeState({
    super.key,
    required this.onQuickPrompt,
    required this.onSuggestion,
  });

  String _greetingForHour(int hour) {
    if (hour < 5) return 'Burning the midnight oil';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Late night';
  }

  String _coachInsight({
    required BuildContext context,
    required int calories,
    required int targetCalories,
    required int protein,
    required int targetProtein,
    required int mealCount,
    required String languageCode,
  }) {
    if (mealCount == 0) {
      return "You haven't logged any meals today. Let's start with a healthy breakfast — what sounds good?";
    }
    if (calories > targetCalories) {
      return "You're a bit over today's calorie goal. Tomorrow, try starting with a lighter breakfast to balance things out.";
    }
    if (calories >= targetCalories * 0.85 &&
        calories <= targetCalories * 1.05) {
      return "You're right on track. One balanced meal to close the day will keep you consistent.";
    }
    if (protein < targetProtein * 0.5) {
      return "Your protein is low today. A high-protein dinner would help — chicken, eggs, tofu, or Greek yogurt work well.";
    }
    if (calories < targetCalories * 0.4) {
      return "You've still got room today. A satisfying dinner with lean protein and complex carbs is a great way to land your goal.";
    }
    return "Steady progress today. Stay mindful of portions and keep moving forward.";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final todaysMeals = ref.watch(todaysMealsProvider).valueOrNull ?? [];

    final hour = DateTime.now().hour;
    final greeting = _greetingForHour(hour);

    final meals = todaysMeals.length;
    final calories = todaysMeals.fold<int>(0, (sum, m) => sum + m.calories);
    final targetCalories =
        settings.valueOrNull?.dailyCalorieGoal ?? 2000;
    final protein = todaysMeals.fold<int>(0, (sum, m) => sum + m.macros.protein);
    final targetProtein =
        settings.valueOrNull?.dailyProteinGoal ?? 120;
    final carbs = todaysMeals.fold<int>(0, (sum, m) => sum + m.macros.carbs);
    final targetCarbs =
        settings.valueOrNull?.dailyCarbGoal ?? 220;
    final fat = todaysMeals.fold<int>(0, (sum, m) => sum + m.macros.fat);
    final targetFat = settings.valueOrNull?.dailyFatGoal ?? 65;

    final insight = _coachInsight(
      context: context,
      calories: calories,
      targetCalories: targetCalories,
      protein: protein,
      targetProtein: targetProtein,
      mealCount: meals,
      languageCode: settings.valueOrNull?.languageCode ?? 'en',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Orb
          Center(child: AiOrb(size: 72))
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 28),

          // Greeting
          Center(
            child: Text(
              greeting,
              style: AppTypography.headlineMedium.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 28,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 6),
          Center(
            child: Text(
              "I'm your AI nutrition coach. What's on your mind?",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecondaryColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 140.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 32),

          // Insight card (single, calm)
          _InsightCard(text: insight, mealCount: meals)
              .animate()
              .fadeIn(delay: 220.ms, duration: 400.ms)
              .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 20),

          // Metric strip
          MetricProgressStrip(
            calories: calories,
            targetCalories: targetCalories,
            protein: protein,
            targetProtein: targetProtein,
            carbs: carbs,
            targetCarbs: targetCarbs,
            fat: fat,
            targetFat: targetFat,
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 28),

          // Quick prompts
          Text(
            'TRY ASKING',
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          )
              .animate()
              .fadeIn(delay: 360.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickPromptChip(
                icon: AppSymbols.utensils,
                label: 'Plan my next meal',
                onTap: () => onQuickPrompt(
                    'Suggest a meal that fits my remaining calories today.'),
              ),
              _QuickPromptChip(
                icon: AppSymbols.target,
                label: 'How are my macros?',
                onTap: () => onQuickPrompt(
                    'Look at my macros today. What should I focus on?'),
              ),
              _QuickPromptChip(
                icon: AppSymbols.lightbulb,
                label: 'Quick nutrition tips',
                onTap: () => onQuickPrompt(
                    'Give me 3 quick, practical nutrition tips for today.'),
              ),
              _QuickPromptChip(
                icon: AppSymbols.leaf,
                label: 'Help me hit protein',
                onTap: () => onQuickPrompt(
                    'I want to hit my protein goal — what should I eat next?'),
              ),
              _QuickPromptChip(
                icon: AppSymbols.barChart3,
                label: 'Weekly check-in',
                onTap: () => onQuickPrompt(
                    'How did this week go compared to my goal?'),
              ),
            ]
                .map(
                  (w) => w
                      .animate()
                      .fadeIn(delay: 420.ms, duration: 300.ms)
                      .slideY(begin: 0.1, end: 0),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;
  final int mealCount;
  const _InsightCard({required this.text, required this.mealCount});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.homeCoachAccent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.cardBorderColor, width: 1),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppSymbols.sparkles,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'TODAY\'S FOCUS',
                style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              Text(
                mealCount == 0
                    ? 'No meals yet'
                    : '$mealCount meal${mealCount == 1 ? '' : 's'} logged',
                style: AppTypography.labelSmall.copyWith(
                  color: context.textMutedColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w500,
              height: 1.55,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickPromptChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.cardBorderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.homeCoachAccent),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
