import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
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
import 'screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Don't await here! Launch UI immediately.
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
            ChangeNotifierProvider(
              create:
                  (context) =>
                      MetricsProvider(context.read<SettingsProvider>()),
            ),
            ChangeNotifierProvider(
              create:
                  (context) => PlannerProvider(
                    _aiService,
                    context.read<SettingsProvider>(),
                  ),
            ),
          ],
          child: const ConnectedApp(),
        );
      },
    );
  }
}

/// The actual app content once providers are ready
class ConnectedApp extends StatelessWidget {
  const ConnectedApp({super.key});

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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If no user, trigger Lazy Auth (Anonymous)
        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthProvider>().signInAnonymously();
          });
          return const MaterialApp(
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        }

        // 2. Show Main App with dynamic theme
        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            return MaterialApp.router(
              title: 'SnapCal',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: _getThemeMode(settingsProvider.themeMode),
              routerConfig: appRouter,
            );
          },
        );
      },
    );
  }
}
