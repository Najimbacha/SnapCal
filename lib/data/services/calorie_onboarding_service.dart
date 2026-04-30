import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/services/config_service.dart';

typedef OnboardingAiBuilder =
    Future<Map<String, dynamic>?> Function(
      OnboardingProfileInput input,
      int dailyCalories,
      String goalMode,
      double weeklyRateKg,
    );

class OnboardingProfileInput {
  final int age;
  final String gender;
  final double heightCm;
  final double currentWeightKg;
  final double goalWeightKg;
  final int timelineMonths;
  final String activityLevel;
  final String weightUnit;
  final String heightUnit;

  const OnboardingProfileInput({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.currentWeightKg,
    required this.goalWeightKg,
    required this.timelineMonths,
    required this.activityLevel,
    required this.weightUnit,
    required this.heightUnit,
  });
}

class OnboardingRecommendation {
  final int dailyCalories;
  final int proteinGrams;
  final int carbGrams;
  final int fatGrams;
  final String insight;
  final String tip;
  final String safetyNote;
  final String goalMode;
  final double weeklyRateKg;
  final bool paceAdjusted;
  final bool usedFallback;
  final bool isMinor;
  final double bmr;
  final double tdee;

  const OnboardingRecommendation({
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    required this.insight,
    required this.tip,
    required this.safetyNote,
    required this.goalMode,
    required this.weeklyRateKg,
    required this.paceAdjusted,
    required this.usedFallback,
    required this.isMinor,
    required this.bmr,
    required this.tdee,
  });
}

class CalorieOnboardingService {
  CalorieOnboardingService({Dio? dio, OnboardingAiBuilder? aiBuilder})
    : _dio = dio ?? Dio(),
      _aiBuilder = aiBuilder;

  final Dio _dio;
  final OnboardingAiBuilder? _aiBuilder;

  static const Map<String, double> _activityMultipliers = {
    'desk_life': 1.2,
    'light_mover': 1.375,
    'active': 1.55,
    'athlete': 1.725,
  };

  Future<OnboardingRecommendation> buildRecommendation(
    OnboardingProfileInput input,
  ) async {
    final computed = _computeBasePlan(input);

    final startedAt = DateTime.now();
    final aiFuture =
        _aiBuilder?.call(
          input,
          computed.dailyCalories,
          computed.goalMode,
          computed.weeklyRateKg,
        ) ??
        _generateAiLayer(input, computed);

    Map<String, dynamic>? aiPayload;
    try {
      aiPayload = await aiFuture.timeout(const Duration(seconds: 3));
    } catch (_) {
      aiPayload = null;
    }

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < const Duration(milliseconds: 1100)) {
      await Future.delayed(const Duration(milliseconds: 1100) - elapsed);
    }

    return OnboardingRecommendation(
      dailyCalories: computed.dailyCalories,
      proteinGrams: computed.proteinGrams,
      carbGrams: computed.carbGrams,
      fatGrams: computed.fatGrams,
      insight:
          aiPayload?['insight'] as String? ??
          _fallbackInsight(input, computed.dailyCalories),
      tip:
          aiPayload?['tip'] as String? ??
          _fallbackTip(input.activityLevel, computed.goalMode),
      safetyNote: computed.safetyNote,
      goalMode: computed.goalMode,
      weeklyRateKg: computed.weeklyRateKg,
      paceAdjusted: computed.paceAdjusted,
      usedFallback: aiPayload == null,
      isMinor: input.age < 16,
      bmr: computed.bmr,
      tdee: computed.tdee,
    );
  }

  _ComputedPlan _computeBasePlan(OnboardingProfileInput input) {
    final genderFactor = input.gender == 'male' ? 5 : -161;
    final bmr =
        (10 * input.currentWeightKg) +
        (6.25 * input.heightCm) -
        (5 * input.age) +
        genderFactor;
    final tdee = bmr * (_activityMultipliers[input.activityLevel] ?? 1.55);

    final deltaKg = input.goalWeightKg - input.currentWeightKg;
    final totalDays = (input.timelineMonths * 30.4375).round().clamp(30, 366);
    final rawAdjustment = (deltaKg * 7700) / totalDays;

    var goalMode = 'maintain';
    if (deltaKg < -0.01) goalMode = 'cut';
    if (deltaKg > 0.01) goalMode = 'bulk';

    var adjustment = rawAdjustment;
    var paceAdjusted = false;
    var safetyNote = '';

    if (goalMode == 'cut') {
      final weeklyLossKg = (adjustment.abs() * 7) / 7700;
      if (weeklyLossKg > 1) {
        adjustment = -(7700 / 7);
        paceAdjusted = true;
        safetyNote = "We'll suggest a safer pace.";
      }
    }

    if (goalMode == 'bulk' && adjustment > 500) {
      adjustment = 500;
      paceAdjusted = true;
      safetyNote = 'We capped the surplus to keep the plan realistic.';
    }

    var targetCalories = tdee + adjustment;
    final floor = input.gender == 'male' ? 1500 : 1200;
    if (targetCalories < floor) {
      targetCalories = floor.toDouble();
      paceAdjusted = true;
      safetyNote =
          safetyNote.isEmpty
              ? 'We kept your target above the minimum safe calorie floor.'
              : '$safetyNote Minimum calorie floor applied.';
    }

    final roundedCalories = (targetCalories / 25).round() * 25;
    final calorieDelta = roundedCalories - tdee;
    final weeklyRateKg = ((calorieDelta * 7) / 7700).abs();
    final macroSplit = _buildMacros(goalMode, roundedCalories);

    return _ComputedPlan(
      bmr: bmr,
      tdee: tdee,
      dailyCalories: roundedCalories,
      proteinGrams: macroSplit.$1,
      carbGrams: macroSplit.$2,
      fatGrams: macroSplit.$3,
      goalMode: goalMode,
      weeklyRateKg: weeklyRateKg,
      paceAdjusted: paceAdjusted,
      safetyNote: safetyNote,
    );
  }

  (int, int, int) _buildMacros(String goalMode, int calories) {
    double proteinRatio = 0.3;
    double carbRatio = 0.4;
    double fatRatio = 0.3;

    switch (goalMode) {
      case 'cut':
        proteinRatio = 0.35;
        carbRatio = 0.35;
        fatRatio = 0.30;
        break;
      case 'bulk':
        proteinRatio = 0.25;
        carbRatio = 0.5;
        fatRatio = 0.25;
        break;
      case 'maintain':
        proteinRatio = 0.3;
        carbRatio = 0.4;
        fatRatio = 0.3;
        break;
    }

    final protein = ((calories * proteinRatio) / 4).round();
    final carbs = ((calories * carbRatio) / 4).round();
    final fat = ((calories * fatRatio) / 9).round();
    return (protein, carbs, fat);
  }

  Future<Map<String, dynamic>?> _generateAiLayer(
    OnboardingProfileInput input,
    _ComputedPlan computed,
  ) async {
    final apiKey = ConfigService().geminiApiKey;
    final modelId = ConfigService().geminiModelId;

    if (apiKey.isEmpty) {
      return null;
    }

    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: {
        'contents': [
          {
            'parts': [
              {'text': _buildPrompt(input, computed)},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.5,
          'topK': 24,
          'topP': 0.9,
          'maxOutputTokens': 250,
        },
      },
    );

    final text =
        response.data['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String?;
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) return null;
      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      return {
        'insight': parsed['insight']?.toString().trim(),
        'tip': parsed['tip']?.toString().trim(),
      };
    } catch (_) {
      return null;
    }
  }

  String _buildPrompt(OnboardingProfileInput input, _ComputedPlan computed) {
    return '''
You are writing onboarding copy for a calorie calculator app.
Return raw JSON only:
{"insight":"string","tip":"string"}

User profile:
- Age: ${input.age}
- Gender: ${input.gender}
- Height: ${input.heightCm.toStringAsFixed(1)} cm
- Current weight: ${input.currentWeightKg.toStringAsFixed(1)} kg
- Goal weight: ${input.goalWeightKg.toStringAsFixed(1)} kg
- Timeline: ${input.timelineMonths} months
- Activity level: ${input.activityLevel}

Computed plan:
- BMR: ${computed.bmr.toStringAsFixed(0)}
- TDEE: ${computed.tdee.toStringAsFixed(0)}
- Daily calories: ${computed.dailyCalories}
- Goal mode: ${computed.goalMode}
- Weekly rate: ${computed.weeklyRateKg.toStringAsFixed(2)} kg/week
- Protein: ${computed.proteinGrams} g
- Carbs: ${computed.carbGrams} g
- Fat: ${computed.fatGrams} g
- Safety note: ${computed.safetyNote.isEmpty ? 'none' : computed.safetyNote}

Rules:
- Keep insight to one sentence, under 22 words.
- Keep tip to one sentence, under 18 words.
- Do not recalculate the plan.
- If the pace was adjusted, reflect that gently.
- Make the tip specific to the activity level.
''';
  }

  String _fallbackInsight(OnboardingProfileInput input, int calories) {
    switch (input.activityLevel) {
      case 'desk_life':
        return '$calories kcal keeps your plan realistic while matching a lower-activity routine.';
      case 'light_mover':
        return '$calories kcal gives you a steady target that fits light weekly movement.';
      case 'athlete':
        return '$calories kcal supports training demand without pushing the pace too hard.';
      default:
        return '$calories kcal balances your goal, body size, and current activity level.';
    }
  }

  String _fallbackTip(String activityLevel, String goalMode) {
    switch (activityLevel) {
      case 'desk_life':
        return 'A 20-minute walk after meals is an easy way to improve consistency.';
      case 'light_mover':
        return 'Two extra movement sessions each week will make this target easier to sustain.';
      case 'athlete':
        return 'Anchor protein across each meal so training recovery stays ahead of appetite swings.';
      default:
        return goalMode == 'bulk'
            ? 'Keep most extra calories around training so the surplus works for performance.'
            : 'Build meals around protein first so the target feels easier to hit.';
    }
  }
}

class _ComputedPlan {
  final double bmr;
  final double tdee;
  final int dailyCalories;
  final int proteinGrams;
  final int carbGrams;
  final int fatGrams;
  final String goalMode;
  final double weeklyRateKg;
  final bool paceAdjusted;
  final String safetyNote;

  const _ComputedPlan({
    required this.bmr,
    required this.tdee,
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    required this.goalMode,
    required this.weeklyRateKg,
    required this.paceAdjusted,
    required this.safetyNote,
  });
}
