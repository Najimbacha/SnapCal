/// SnapCal App Constants
class AppConstants {
  AppConstants._();

  // API Configuration (Managed via Firebase Remote Config)
  static const String defaultGeminiApiKey = 'Your-Gemini-Key';
  static const String defaultGroqApiKey = 'Your-Groq-Key';
  
  // Model IDs
  static const String defaultGeminiModel = 'gemini-2.5-flash';
  static const String defaultGroqCoachModel = 'llama-3.1-8b-instant';
  static const String defaultGroqScannerModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static const String groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // System Prompt for Gemini
  static const String geminiSystemPrompt = '''
You are a Nutritionist AI analyzing food images.

Output ONLY a raw JSON object with no markdown formatting, no code blocks, no explanatory text.

Return this exact structure:
{
  "items": [
    {
      "food_name": "string", 
      "portion": "string", 
      "calories": number, 
      "protein": number, 
      "carbs": number, 
      "fat": number,
      "health_score": number, (1-10 scale)
      "insights": ["string", "string"] (Max 3 short tags like "High Fiber", "Healthy Fats", "Low Sugar")
    }
  ]
}

Rules:
- Each distinct food item visible on the plate gets its own entry in the "items" array
- health_score is based on nutritional density (10 = superfood, 1 = junk food)
- insights should be short (1-2 words) positive or cautionary highlights
- If only one food item is visible, still wrap it in the "items" array
- All nutritional values are for a typical single serving of that specific item
- protein, carbs, fat are in grams
- If unclear or partially visible food, provide your best estimate
- If NOT food at all, return: {"items": [{"food_name": "Not food", "health_score": 0, "insights": ["Invalid Object"], "calories": 0, "protein": 0, "carbs": 0, "fat": 0}]}

Example for a plate with rice and chicken:
{"items": [{"food_name": "Steamed white rice", "health_score": 6, "insights": ["Complex Carbs"], "calories": 206, "protein": 4, "carbs": 45, "fat": 0}, {"food_name": "Grilled chicken breast", "health_score": 9, "insights": ["High Protein", "Lean Meat"], "calories": 165, "protein": 31, "carbs": 0, "fat": 4}]}
''';

  // Storage Keys
  static const String mealsBoxName = 'meals_box';
  static const String mealIndexBoxName = 'meal_index_box';
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
  static const int maxImageSize = 768;
  static const int imageQuality = 70;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
