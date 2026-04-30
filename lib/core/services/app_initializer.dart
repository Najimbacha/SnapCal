import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:snapcal/core/services/config_service.dart';
import 'package:snapcal/data/services/notification_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

import '../../data/services/gemini_service.dart';
import '../../data/services/barcode_service.dart';
import '../../data/services/subscription_service.dart';
import '../../data/services/scan_gate_service.dart';
import '../../data/services/ad_service.dart';

class AppInitializer {
  static Future<void> preInit() async {
    await _initFirebase();
  }

  static Future<void> init({
    required MealRepository mealRepository,
    required SettingsRepository settingsRepository,
    required WaterRepository waterRepository,
    required AssistantRepository assistantRepository,
  }) async {
    final startTime = DateTime.now();
    debugPrint('🚀 AppInitializer: Starting initialization...');

    // 1. Critical System UI (Edge-to-Edge Support for Android 15+)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 2. Critical: Initialize Firebase FIRST before any dependent services
    await _initFirebase();

    // 3. Initialize Hive first since repositories depend on it
    await _initHive();

    // 4. Initialize Repositories (CRITICAL)
    await Future.wait([
      mealRepository.init(),
      settingsRepository.init(),
      waterRepository.init(),
      assistantRepository.init(),
    ]);

    // 5. Background Initialization for non-critical services
    // We don't await this so the app can launch immediately
    _initBackgroundServices(settingsRepository);

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    debugPrint('✅ AppInitializer: Critical core ready in ${duration}ms');
  }

  static Future<void> _initBackgroundServices(SettingsRepository settingsRepository) async {
    try {
      await Future.wait([
        NotificationService().init(),
        ConfigService().init(),
        GoogleSignIn.instance.initialize(),
        SubscriptionService.init(settingsRepository),
        ScanGateService().init(),
        AdService().init(),
        _warmupSingletons(),
      ]);
      debugPrint('⚡ Background services ready');
    } catch (e) {
      debugPrint('⚠️ Background service init warning: $e');
    }
  }

  static Future<void> _warmupSingletons() async {
    // Simply instantiating the singletons triggers their Dio/internal setup
    AIService();
    BarcodeService();
    debugPrint('⚡ Services warmed up');
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
