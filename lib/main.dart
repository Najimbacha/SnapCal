import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';
import 'core/services/app_initializer.dart'; // Import AppInitializer
import 'data/repositories/meal_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/water_repository.dart';
import 'data/repositories/assistant_repository.dart';
import 'data/services/gemini_service.dart';
import 'providers/meal_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/assistant_provider.dart';
import 'providers/metrics_provider.dart';
import 'providers/planner_provider.dart';
import 'providers/water_provider.dart'; // Re-added
import 'data/services/connectivity_service.dart';
import 'screens/splash/splash_screen.dart';

import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;

  // Fast init for Firebase/Crashlytics
  try {
    await AppInitializer.preInit();
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase pre-init failed: $e');
  }
  
  FlutterError.onError = (errorDetails) {
    if (firebaseInitialized) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } else {
      FlutterError.presentError(errorDetails);
    }
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    if (firebaseInitialized) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      debugPrint('Error before Firebase init: $error');
    }
    return true;
  };

  runApp(const SnapCalApp());
}

class SnapCalApp extends StatefulWidget {
  const SnapCalApp({super.key});

  @override
  State<SnapCalApp> createState() => _SnapCalAppState();
}

class _SnapCalAppState extends State<SnapCalApp> {
  // Repositories & Services
  late final MealRepository _mealRepository;
  late final SettingsRepository _settingsRepository;
  late final WaterRepository _waterRepository;
  late final AssistantRepository _assistantRepository;
  late final AIService _aiService;

  // Initialization State
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // 1. Create instances immediately (sync)
    _mealRepository = MealRepository();
    _settingsRepository = SettingsRepository();
    _waterRepository = WaterRepository();
    _assistantRepository = AssistantRepository();
    _aiService = AIService();

    // 2. Start Async Initialization
    _initFuture = AppInitializer.init(
      mealRepository: _mealRepository,
      settingsRepository: _settingsRepository,
      waterRepository: _waterRepository,
      assistantRepository: _assistantRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // Show Splash while initializing
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        }

        // Initialization Complete: Build App Tree
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ConnectivityService()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(
              create: (_) => SettingsProvider(_settingsRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => MealProvider(_mealRepository),
            ),
            ChangeNotifierProvider(
              create: (_) => WaterProvider(_waterRepository),
            ),
            ChangeNotifierProvider<AssistantProvider>(
              create: (context) => AssistantProvider(_assistantRepository),
            ),
            ChangeNotifierProxyProvider<SettingsProvider, MetricsProvider>(
              create:
                  (context) =>
                      MetricsProvider(context.read<SettingsProvider>()),
              update:
                  (context, settings, metrics) =>
                      metrics!..updateSettings(settings),
            ),
            ChangeNotifierProxyProvider<SettingsProvider, PlannerProvider>(
              create:
                  (context) => PlannerProvider(
                    _aiService,
                    context.read<SettingsProvider>(),
                  ),
              update:
                  (context, settings, planner) =>
                      planner!..updateSettings(settings),
            ),
          ],
          child: const AppRouterWrapper(),
        );
      },
    );
  }
}

/// A wrapper widget that initializes the GoRouter once providers are available.
class AppRouterWrapper extends StatefulWidget {
  const AppRouterWrapper({super.key});

  @override
  State<AppRouterWrapper> createState() => _AppRouterWrapperState();
}

class _AppRouterWrapperState extends State<AppRouterWrapper> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Initialize the router with the providers from the context
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    _router = createRouter(auth, settings);
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                return MaterialApp.router(
                  title: 'SnapCal',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme.copyWith(
                    colorScheme: lightDynamic ?? AppTheme.lightTheme.colorScheme,
                  ),
                  darkTheme: AppTheme.darkTheme.copyWith(
                    colorScheme: darkDynamic ?? AppTheme.darkTheme.colorScheme,
                  ),
                  themeMode: _getThemeMode(settingsProvider.themeMode),
                  routerConfig: _router,
                  builder: (context, child) {
                    // Global Error Boundary
                    ErrorWidget.builder = (details) => _GlobalErrorView(details: details);
                    
                    // 1. Handle Unauthenticated / Initial / Loading states
                    if (auth.status == AuthStatus.initial ||
                        auth.status == AuthStatus.loading) {
                      return const SplashScreen();
                    }

                    // Trigger anonymous sign-in if completely unauthenticated
                    if (auth.status == AuthStatus.unauthenticated && auth.user == null) {
                      auth.signInAnonymously();
                      return const SplashScreen();
                    }

                    // 2. Handle Fatal Error state
                    if (auth.status == AuthStatus.error && auth.user == null) {
                      return Scaffold(
                        body: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.orange),
                                const SizedBox(height: 24),
                                Text(
                                  'Connection Issue',
                                  style: AppTheme.darkTheme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  auth.errorMessage ?? 'Unable to initialize SnapCal. Please check your data or Wi-Fi.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 32),
                                FilledButton.icon(
                                  onPressed: () {
                                    auth.clearError();
                                    auth.signInAnonymously();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // 3. Normal App Flow
                    return child!;
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GlobalErrorView extends StatelessWidget {
  final FlutterErrorDetails details;
  const _GlobalErrorView({required this.details});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.alertTriangle, size: 64, color: Colors.redAccent),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We encountered an unexpected error. Our team has been notified and we are working to fix it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () {
                    // Force restart or reload
                    // In a real app, you might want to clear some cache
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(LucideIcons.refreshCcw, size: 20),
                  label: const Text('Try to Reload', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
