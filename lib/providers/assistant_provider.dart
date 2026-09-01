import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/meal.dart';
import '../data/repositories/assistant_repository.dart';
import '../data/services/assistant_service.dart';
import '../data/services/gemini_service.dart';
import 'meal_provider.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';

part 'assistant_provider.g.dart';

@Riverpod(keepAlive: true)
class Assistant extends _$Assistant {
  AssistantRepository? _repo;
  final AIService _aiService = AIService();

  @override
  FutureOr<void> build() {}

  /// One coach turn.
  ///
  /// This used to send the user's raw text straight to the model — no persona,
  /// no profile, no history — so Fajar had never been told she was a
  /// nutritionist and could not see the numbers the app already had. The
  /// prompt that does all of that existed in AssistantService and was never
  /// called from anywhere. It is called from here now.
  Future<String> fetchRecommendations(
    String query, {
    int? currentCalories,
    List<Map<String, String>> history = const [],
  }) async {
    _repo ??= await ref.read(assistantRepositoryProvider.future);
    if (currentCalories != null) {
      await _repo!.saveCalorieSnapshot(currentCalories);
    }

    final settings = ref.read(settingsProvider).valueOrNull;
    final meals = ref.read(todaysMealsProvider).valueOrNull ?? const <Meal>[];

    int sum(int Function(Meal) pick) =>
        meals.fold<int>(0, (total, m) => total + pick(m));

    final prompt = AssistantService().buildCoachPrompt(
      currentCalories: sum((m) => m.calories),
      targetCalories: settings?.dailyCalorieGoal ?? 2000,
      currentMacros: {
        'protein': sum((m) => m.macros.protein),
        'carbs': sum((m) => m.macros.carbs),
        'fat': sum((m) => m.macros.fat),
      },
      targetMacros: {
        'protein': settings?.dailyProteinGoal ?? 50,
        'carbs': settings?.dailyCarbGoal ?? 250,
        'fat': settings?.dailyFatGoal ?? 65,
      },
      mealNames: meals.map((m) => m.foodName).toList(),
      dietaryRestriction: settings?.dietaryRestriction ?? 'none',
      userQuery: query.isEmpty ? null : query,
      language: settings?.languageCode ?? 'en',
      age: settings?.age,
      gender: settings?.gender,
      height: settings?.height,
      // UserSettings carries no current weight — it lives with the weight log —
      // so the coach is told the target and left to ask if it needs the rest.
      targetWeight: settings?.targetWeight,
      goalMode: settings?.goalMode,
      activityLevel: settings?.activityLevel,
      foodDislikes: settings?.foodDislikes,
      medicalNotes: settings?.medicalNotes,
      history: history,
    );

    return _aiService.generateText(prompt);
  }

  Future<String> analyzeImage(String base64Image, String prompt) async {
    final bytes = Uri.tryParse(base64Image)?.data?.contentAsBytes();
    if (bytes == null) return 'Error: Invalid image data';
    final result = await _aiService.analyzeFood(bytes);
    return result.toString();
  }
}
