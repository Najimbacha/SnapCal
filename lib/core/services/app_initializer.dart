import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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
import '../../data/models/meal_template.dart';
import '../../data/models/achievement.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/water_repository.dart';
import '../../data/repositories/assistant_repository.dart';

import '../../data/services/gemini_service.dart';
import '../../data/services/barcode_service.dart';
import '../../data/services/subscription_service.dart';
import '../../data/services/scan_gate_service.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/widget_service.dart';

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

    try {
      debugPrint('🚀 AppInitializer: Setting System UI...');
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

      debugPrint('🚀 AppInitializer: Initializing Firebase...');
      // 2. Critical: Initialize Firebase FIRST
      await _initFirebase();

      debugPrint('🚀 AppInitializer: Initializing Hive...');
      // 3. Initialize Hive
      await _initHive();

      debugPrint('🚀 AppInitializer: Initializing Repositories...');
      // 4. Initialize Repositories (CRITICAL)
      await Future.wait([
        mealRepository.init(),
        settingsRepository.init(),
        waterRepository.init(),
        assistantRepository.init(),
      ]).timeout(const Duration(seconds: 20));

      debugPrint('🚀 AppInitializer: Starting background services...');
      // 5. Background Initialization
      _initBackgroundServices(settingsRepository);

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('✅ AppInitializer: Critical core ready in ${duration}ms');
    } catch (e, stack) {
      debugPrint('❌ AppInitializer: Fatal error during initialization: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  static Future<void> _initBackgroundServices(
    SettingsRepository settingsRepository,
  ) async {
    try {
      await Future.wait([
        NotificationService().init(),
        ConfigService().init(),
        _initGoogleSignIn(), // Isolated initialization with timeout
        SubscriptionService.init(settingsRepository),
        ScanGateService().init(),
        AdService().init(),
        WidgetService.init(),
        _warmupSingletons(),
      ]).timeout(const Duration(seconds: 15));
      debugPrint('⚡ Background services ready');
    } catch (e) {
      debugPrint('⚠️ Background service init warning: $e');
    }
  }

  static Future<void> _initGoogleSignIn() async {
    try {
      debugPrint('🎬 AppInitializer: Initializing GoogleSignIn...');
      await GoogleSignIn.instance
          .initialize(
            serverClientId:
                '183409999145-2p9nqjrr8d07ulal61nupsefkh7pt9on.apps.googleusercontent.com',
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint(
                '⚠️ AppInitializer: GoogleSignIn initialization timed out',
              );
            },
          );
    } catch (e) {
      debugPrint('⚠️ AppInitializer: GoogleSignIn initialization warning: $e');
    }
  }

  static Future<void> _warmupSingletons() async {
    AIService();
    BarcodeService();
    debugPrint('⚡ Services warmed up');
  }

  static Future<void> _initFirebase() async {
    try {
      debugPrint('🔥 Firebase: Checking if already initialized...');
      if (Firebase.apps.isEmpty) {
        debugPrint('🔥 Firebase: Calling initializeApp()...');
        await Firebase.initializeApp().timeout(const Duration(seconds: 15));
        debugPrint('🔥 Firebase: initializeApp() completed');

        // Enable Crashlytics in Release mode
        if (!kDebugMode) {
          debugPrint('🔥 Firebase: Enabling Crashlytics collection...');
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
            true,
          );
          debugPrint('🔥 Firebase: Crashlytics collection enabled');
        }

        // Setup Global Error Handling now that Firebase is ready
        debugPrint('🔥 Firebase: Setting up error reporting...');
        _setupErrorReporting();

        debugPrint('🔥 Firebase initialized and Error Reporting active');
      } else {
        debugPrint('🔥 Firebase already initialized');
      }
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      // Rethrow to ensure the UI shows the retry screen instead of hanging in a half-initialized state
      rethrow;
    }
  }

  static void _setupErrorReporting() {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      FlutterError.presentError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    debugPrint('🛡️ Crashlytics Error Reporting configured');
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
    Hive.registerAdapter(TemplateItemAdapter());
    Hive.registerAdapter(MealTemplateAdapter());
    Hive.registerAdapter(AchievementAdapter());

    debugPrint('📦 Hive initialized');
  }
}
