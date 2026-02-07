/// SnapCal App Constants
class AppConstants {
  AppConstants._();

  // API Configuration
  // TODO: Replace with your actual API keys (do NOT commit real keys!)
  static const String geminiApiKey = 'AIzaSyCdAdk3ER8ZD8Gmj36plQCTiDVbKJMeeB0';
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  static const String groqApiKey =
      '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';
  static const String groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // System Prompt for Gemini
  static const String geminiSystemPrompt = '''
You are a Nutritionist AI analyzing food images.

Output ONLY a raw JSON object with no markdown formatting, no code blocks, no explanatory text.

Return this exact structure:
{
  "food_name": "string",
  "calories": number,
  "protein": number,
  "carbs": number,
  "fat": number
}

Rules:
- All nutritional values are for a typical single serving
- protein, carbs, fat are in grams
- If multiple food items, combine into one entry or focus on the main item
- If unclear or partially visible food, provide your best estimate
- If NOT food at all, return: {"food_name": "Not food", "calories": 0, "protein": 0, "carbs": 0, "fat": 0}

Example valid output:
{"food_name": "Grilled chicken breast", "calories": 165, "protein": 31, "carbs": 0, "fat": 4}
''';

  // Storage Keys
  static const String mealsBoxName = 'meals_box';
  static const String settingsBoxName = 'settings_box';
  static const String waterBoxName = 'water_box';
  static const String assistantBoxName = 'assistant_box';
  static const String settingsKey = 'user_settings';

  // Default User Goals
  static const int defaultCalorieGoal = 2000;
  static const int defaultProteinGoal = 150;
  static const int defaultCarbGoal = 200;
  static const int defaultFatGoal = 60;
  static const int defaultWaterGoal = 2000; // in ml

  // Free Tier Limits
  static const int freeTierDailyMealLimit = 3;

  // Image Processing
  static const int maxImageSize = 800;
  static const int imageQuality = 70;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
