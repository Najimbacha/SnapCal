import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:snapcal/data/services/notification_service.dart';
import '../../data/models/meal.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/water_log.dart';
import '../../data/models/body_metric.dart';
import '../../data/models/grocery_item.dart';
import '../../data/models/meal_plan.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/water_repository.dart';
import '../../data/repositories/assistant_repository.dart';

class AppInitializer {
  static Future<void> init({
    required MealRepository mealRepository,
    required SettingsRepository settingsRepository,
    required WaterRepository waterRepository,
    required AssistantRepository assistantRepository,
  }) async {
    final startTime = DateTime.now();
    debugPrint('🚀 AppInitializer: Starting initialization...');

    // 1. Critical System UI (Mental Perceived Performance)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1E1E1E),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 2. Parallel Initialization of Heavy Services
    await Future.wait([
      _initFirebase(),
      _initHive(),
      NotificationService().init(),
    ]);

    // 3. Initialize Repositories (Dependent on Hive)
    await Future.wait([
      mealRepository.init(),
      settingsRepository.init(),
      waterRepository.init(),
      assistantRepository.init(),
    ]);

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    debugPrint('✅ AppInitializer: Completed in ${duration}ms');
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
      debugPrint('🔥 Firebase initialized');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
    }
  }

  static Future<void> _initHive() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(MacrosAdapter());
    Hive.registerAdapter(MealAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
    Hive.registerAdapter(WaterLogAdapter());
    Hive.registerAdapter(BodyMetricAdapter());
    Hive.registerAdapter(GroceryItemAdapter());
    Hive.registerAdapter(MealPlanAdapter());

    debugPrint('📦 Hive initialized');
  }
}
