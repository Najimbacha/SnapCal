/// SnapCal App Constants
class AppConstants {
  AppConstants._();

  // API Configuration
  // TODO: Replace with your actual API keys (do NOT commit real keys!)
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String groqApiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // System Prompt for Gemini
  static const String geminiSystemPrompt = '''
You are a Nutritionist AI. Analyze this image.
Output ONLY a raw JSON object. 
Do NOT use markdown code blocks (```). 
Do NOT add any intro text. 
Do NOT explain your answer.

Return this exact JSON structure:
{
  "food_name": "String (descriptive name)",
  "calories": Integer,
  "protein": Integer (grams),
  "carbs": Integer (grams),
  "fat": Integer (grams)
}

If the image is unclear, guess. 
If it is NOT food, return: {"food_name": "Unknown Food", "calories": 0, "protein": 0, "carbs": 0, "fat": 0}
''';

  // Storage Keys
  static const String mealsBoxName = 'meals_box';
  static const String settingsBoxName = 'settings_box';
  static const String waterBoxName = 'water_box';
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
  static const int maxImageSize = 1024;
  static const int imageQuality = 85;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
