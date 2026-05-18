import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../../core/services/config_service.dart';
import '../../l10n/generated/app_localizations.dart';

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
    OnboardingProfileInput input, {
    String languageCode = 'en',
  }) async {
    final l10n = _l10n(languageCode);
    final computed = _computeBasePlanData(input, l10n);

    final startedAt = DateTime.now();
    final aiFuture =
        _aiBuilder?.call(
          input,
          computed.dailyCalories,
          computed.goalMode,
          computed.weeklyRateKg,
        ) ??
        _generateAiLayer(input, computed, languageCode);

    Map<String, dynamic>? aiPayload;
    try {
      // Reduced timeout to 2.5s for snappier onboarding feel
      aiPayload = await aiFuture.timeout(const Duration(milliseconds: 2500));
    } on DioException catch (e) {
      debugPrint('CalorieOnboardingService: Dio Error: ${e.message}');
      aiPayload = null;
    } catch (e) {
      debugPrint('CalorieOnboardingService: Unexpected Error: $e');
      aiPayload = null;
    }

    final elapsed = DateTime.now().difference(startedAt);
    // Minimal delay (200ms) for smoother UI transitions
    if (elapsed < const Duration(milliseconds: 200)) {
      await Future.delayed(const Duration(milliseconds: 200) - elapsed);
    }

    return OnboardingRecommendation(
      dailyCalories: computed.dailyCalories,
      proteinGrams: computed.proteinGrams,
      carbGrams: computed.carbGrams,
      fatGrams: computed.fatGrams,
      insight:
          aiPayload?['insight'] as String? ??
          _fallbackInsight(input, computed.dailyCalories, l10n),
      tip:
          aiPayload?['tip'] as String? ??
          _fallbackTip(input.activityLevel, computed.goalMode, l10n),
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

  OnboardingRecommendation computeBasePlan(
    OnboardingProfileInput input, {
    String languageCode = 'en',
  }) {
    final l10n = _l10n(languageCode);
    final computed = _computeBasePlanData(input, l10n);
    return OnboardingRecommendation(
      dailyCalories: computed.dailyCalories,
      proteinGrams: computed.proteinGrams,
      carbGrams: computed.carbGrams,
      fatGrams: computed.fatGrams,
      insight: _fallbackInsight(input, computed.dailyCalories, l10n),
      tip: _fallbackTip(input.activityLevel, computed.goalMode, l10n),
      safetyNote: computed.safetyNote,
      goalMode: computed.goalMode,
      weeklyRateKg: computed.weeklyRateKg,
      paceAdjusted: computed.paceAdjusted,
      usedFallback: true,
      isMinor: input.age < 16,
      bmr: computed.bmr,
      tdee: computed.tdee,
    );
  }

  _ComputedPlan _computeBasePlanData(
    OnboardingProfileInput input,
    AppLocalizations l10n,
  ) {
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
        safetyNote = l10n.onboarding_safety_safer_pace;
      }
    }

    if (goalMode == 'bulk' && adjustment > 500) {
      adjustment = 500;
      paceAdjusted = true;
      safetyNote = l10n.onboarding_safety_surplus_capped;
    }

    var targetCalories = tdee + adjustment;
    final floor = input.gender == 'male' ? 1500 : 1200;
    if (targetCalories < floor) {
      targetCalories = floor.toDouble();
      paceAdjusted = true;
      safetyNote =
          safetyNote.isEmpty
              ? l10n.onboarding_safety_floor
              : l10n.onboarding_safety_floor_extra(safetyNote);
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
    String languageCode,
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
              {'text': _buildPrompt(input, computed, languageCode)},
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

  String _buildPrompt(
    OnboardingProfileInput input,
    _ComputedPlan computed,
    String languageCode,
  ) {
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
- Respond entirely in ${_languageName(languageCode)}.
- Keep insight to one sentence, under 22 words.
- Keep tip to one sentence, under 18 words.
- Do not recalculate the plan.
- If the pace was adjusted, reflect that gently.
- Make the tip specific to the activity level.
''';
  }

  String _fallbackInsight(
    OnboardingProfileInput input,
    int calories,
    AppLocalizations l10n,
  ) {
    switch (input.activityLevel) {
      case 'desk_life':
        return l10n.onboarding_insight_desk(calories);
      case 'light_mover':
        return l10n.onboarding_insight_light(calories);
      case 'athlete':
        return l10n.onboarding_insight_athlete(calories);
      default:
        return l10n.onboarding_insight_default(calories);
    }
  }

  String _fallbackTip(
    String activityLevel,
    String goalMode,
    AppLocalizations l10n,
  ) {
    switch (activityLevel) {
      case 'desk_life':
        return l10n.onboarding_tip_desk;
      case 'light_mover':
        return l10n.onboarding_tip_light;
      case 'athlete':
        return l10n.onboarding_tip_athlete;
      default:
        return goalMode == 'bulk'
            ? l10n.onboarding_tip_bulk
            : l10n.onboarding_tip_default;
    }
  }

  AppLocalizations _l10n(String languageCode) {
    final supported = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == languageCode,
    );
    return lookupAppLocalizations(Locale(supported ? languageCode : 'en'));
  }

  String _languageName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'Arabic';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      default:
        return 'English';
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
