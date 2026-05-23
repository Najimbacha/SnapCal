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
import '../../data/services/premium_gate_service.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/widget_service.dart';
import '../utils/async_guard.dart';

class AppInitializer {
  static bool _errorReportingConfigured = false;

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

      debugPrint(
        '🚀 AppInitializer: Parallelizing Service & Repository Init...',
      );
      // 4. Initialize everything else in parallel after Hive/Firebase are ready
      await Future.wait([
        ScanGateService().init().then(
          (_) => debugPrint('✅ AppInitializer: ScanGate ready'),
        ),
        PremiumGateService().init().then(
          (_) => debugPrint('✅ AppInitializer: PremiumGate ready'),
        ),
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
        NotificationService().init().then(
          (_) => debugPrint('✅ AppInitializer: NotificationService ready'),
        ),
      ]).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⚠️ AppInitializer: Initialization timed out after 30s');
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
      _logInitializerFailure(e, stack);
      _recordInitializerFailure(e, stack);
      debugPrint(stack.toString());
      rethrow;
    }
  }

  static Future<void> _initBackgroundServices(
    SettingsRepository settingsRepository,
  ) async {
    try {
      // 1. Initialize Remote Config first so that subsequent services can read updated API keys/configs.
      await runSilently(
        'Remote config init',
        () => ConfigService().init(),
      ).timeout(const Duration(seconds: 10));

      // 2. Initialize remaining background services in parallel
      await Future.wait([
        runSilently(
          'Subscription init',
          () => SubscriptionService.init(settingsRepository),
        ),
        runSilently('Ad init', () => AdService().init()),
        runSilently('Widget init', WidgetService.init),
        runSilently('Service warmup', _warmupSingletons),
      ]).timeout(const Duration(seconds: 10));
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
        await Firebase.initializeApp().timeout(const Duration(seconds: 30));
        debugPrint('🔥 Firebase: initializeApp() completed');
      } else {
        debugPrint('🔥 Firebase already initialized');
      }
      await _configureCrashlyticsAfterFirebase();
    } catch (e) {
      _logFirebaseInitFailure(e);
      // Rethrow to ensure the UI shows the retry screen instead of hanging in a half-initialized state
      rethrow;
    }
  }

  static Future<void> _configureCrashlyticsAfterFirebase() async {
    // Enable Crashlytics in Release mode
    if (!kDebugMode) {
      debugPrint('🔥 Firebase: Enabling Crashlytics collection...');
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      debugPrint('🔥 Firebase: Crashlytics collection enabled');
    }

    if (_errorReportingConfigured) {
      debugPrint('🔥 Firebase: Error reporting already configured');
      return;
    }

    // Setup Global Error Handling now that Firebase is ready
    debugPrint('🔥 Firebase: Setting up error reporting...');
    _setupErrorReporting();
    _errorReportingConfigured = true;

    debugPrint('🔥 Firebase initialized and Error Reporting active');
  }

  static void _setupErrorReporting() {
    FlutterError.onError = (errorDetails) {
      final fatal = _shouldRecordFlutterErrorAsFatal(
        errorDetails.exception,
        errorDetails.stack,
      );
      unawaited(
        FirebaseCrashlytics.instance.setCustomKey('flutter_error_fatal', fatal),
      );

      if (fatal) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      } else {
        FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      }

      FlutterError.presentError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final fatal = _shouldRecordFlutterErrorAsFatal(error, stack);
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
      return true;
    };
    debugPrint('🛡️ Crashlytics Error Reporting configured');
  }

  static bool _shouldRecordFlutterErrorAsFatal(
    Object error,
    StackTrace? stack,
  ) {
    return !_isNonFatalMouseTrackerAssertion(error, stack) &&
        !_isParentDataWidgetAssertion(error, stack);
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

  static bool _isParentDataWidgetAssertion(Object error, StackTrace? stack) {
    final message = error.toString();
    final stackText = stack?.toString() ?? '';

    return message.contains('Incorrect use of ParentDataWidget') ||
        message.contains('ParentDataWidget') ||
        stackText.contains('RenderObjectElement._updateParentData');
  }

  static void _logInitializerFailure(Object error, StackTrace stack) {
    debugPrint('❌ AppInitializer: Fatal error during initialization');
    debugPrint('❌ AppInitializer: type=${error.runtimeType}');
    if (error is PlatformException) {
      debugPrint('❌ AppInitializer: platformCode=${error.code}');
      debugPrint('❌ AppInitializer: platformMessage=${error.message}');
      debugPrint('❌ AppInitializer: platformDetails=${error.details}');
      if (error.code == 'channel-error') {
        _logNativePluginChannelFailure('AppInitializer');
      }
    } else {
      debugPrint('❌ AppInitializer: error=$error');
    }
    debugPrint('❌ AppInitializer: firebaseApps=${Firebase.apps.length}');
  }

  static void _recordInitializerFailure(Object error, StackTrace stack) {
    if (Firebase.apps.isEmpty) return;

    unawaited(
      FirebaseCrashlytics.instance.setCustomKey(
        'app_initializer_error_type',
        error.runtimeType.toString(),
      ),
    );
    if (error is PlatformException) {
      unawaited(
        FirebaseCrashlytics.instance.setCustomKey(
          'app_initializer_platform_code',
          error.code,
        ),
      );
      unawaited(
        FirebaseCrashlytics.instance.setCustomKey(
          'app_initializer_platform_message',
          error.message ?? '',
        ),
      );
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  }

  static void _logFirebaseInitFailure(Object error) {
    debugPrint('❌ Firebase initialization failed');
    debugPrint('❌ Firebase: type=${error.runtimeType}');
    if (error is PlatformException) {
      debugPrint('❌ Firebase: platformCode=${error.code}');
      debugPrint('❌ Firebase: platformMessage=${error.message}');
      debugPrint('❌ Firebase: platformDetails=${error.details}');
      if (error.code == 'channel-error') {
        _logNativePluginChannelFailure('Firebase');
      }
    } else if (error is TimeoutException) {
      debugPrint('❌ Firebase: timeout=${error.message}');
    } else {
      debugPrint('❌ Firebase: error=$error');
    }
    debugPrint('❌ Firebase: appsAfterFailure=${Firebase.apps.length}');
  }

  static void _logNativePluginChannelFailure(String source) {
    debugPrint(
      '❌ $source: native plugin channel unavailable; verify Android '
      'GeneratedPluginRegistrant.registerWith() ran.',
    );
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
