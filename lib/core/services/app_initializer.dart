import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:snapcal/core/services/config_service.dart';
import 'package:snapcal/data/services/notification_service.dart';
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
import '../utils/async_guard.dart';

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

      debugPrint('🚀 AppInitializer: Initializing scan gate...');
      await ScanGateService().init();

      debugPrint(
        '🚀 AppInitializer: Initializing Repositories (Meal, Settings, Water, Assistant)...',
      );
      // 4. Initialize Repositories (CRITICAL)
      await Future.wait([
        mealRepository.init().then(
          (_) => debugPrint('✅ AppInitializer: MealRepo ready'),
        ),
        settingsRepository.init().then(
          (_) => debugPrint('✅ AppInitializer: SettingsRepo ready'),
        ),
        waterRepository.init().then(
          (_) => debugPrint('✅ AppInitializer: WaterRepo ready'),
        ),
        assistantRepository.init().then(
          (_) => debugPrint('✅ AppInitializer: AssistantRepo ready'),
        ),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
            '⚠️ AppInitializer: Repository initialization timed out after 15s',
          );
          throw TimeoutException(
            'Core data services are taking too long to respond.',
          );
        },
      );

      debugPrint('🚀 AppInitializer: Starting background services...');
      // 5. Background Initialization
      unawaited(_initBackgroundServices(settingsRepository));

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
        runSilently('Notification init', () => NotificationService().init()),
        runSilently('Remote config init', () => ConfigService().init()),
        runSilently(
          'Subscription init',
          () => SubscriptionService.init(settingsRepository),
        ),
        runSilently('Ad init', () => AdService().init()),
        runSilently('Widget init', WidgetService.init),
        runSilently('Service warmup', _warmupSingletons),
      ]).timeout(const Duration(seconds: 15));
      debugPrint('⚡ Background services ready');
    } catch (e) {
      debugPrint('⚠️ Background service init warning: $e');
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
      if (_isNonFatalMouseTrackerAssertion(
        errorDetails.exception,
        errorDetails.stack,
      )) {
        FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
        FlutterError.presentError(errorDetails);
        return;
      }

      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      FlutterError.presentError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (_isNonFatalMouseTrackerAssertion(error, stack)) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
        return true;
      }

      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    debugPrint('🛡️ Crashlytics Error Reporting configured');
  }

  static bool _isNonFatalMouseTrackerAssertion(
    Object error,
    StackTrace? stack,
  ) {
    final message = error.toString();
    final stackText = stack?.toString() ?? '';

    return message.contains('mouse_tracker.dart') ||
        message.contains('!_debugDuringDeviceUpdate') ||
        stackText.contains('MouseTracker.updateAllDevices');
  }

  static Future<void> _initHive() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MacrosAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MealAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(WaterLogAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(BodyMetricAdapter());
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(GroceryItemAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(MealPlanAdapter());
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TemplateItemAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(MealTemplateAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(AchievementAdapter());
    }

    debugPrint('📦 Hive initialized');
  }
}
