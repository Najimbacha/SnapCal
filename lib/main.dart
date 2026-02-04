import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';
import 'package:snapcal/data/services/notification_service.dart';
import 'data/models/meal.dart';
import 'data/models/user_settings.dart';
import 'data/repositories/meal_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'package:snapcal/data/models/water_log.dart';
import 'package:snapcal/data/repositories/water_repository.dart';
import 'package:snapcal/providers/water_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/assistant_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Notification Service
  await NotificationService().init();

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E1E1E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase (wrapped in try-catch to avoid crash if config is missing)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(MacrosAdapter());
  Hive.registerAdapter(MealAdapter());
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(WaterLogAdapter());

  // Initialize repositories
  final mealRepository = MealRepository();
  final settingsRepository = SettingsRepository();
  final waterRepository = WaterRepository();

  await mealRepository.init();
  await settingsRepository.init();
  await waterRepository.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsRepository),
        ),
        ChangeNotifierProvider(create: (_) => MealProvider(mealRepository)),
        ChangeNotifierProvider(create: (_) => WaterProvider(waterRepository)),
        ChangeNotifierProvider(create: (_) => AssistantProvider()),
      ],
      child: const SnapCalApp(),
    ),
  );
}

class SnapCalApp extends StatefulWidget {
  const SnapCalApp({super.key});

  @override
  State<SnapCalApp> createState() => _SnapCalAppState();
}

class _SnapCalAppState extends State<SnapCalApp> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Check persistence/connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            key: ValueKey('splash_loading'),
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        }

        // 2. If no user (and not waiting), trigger Lazy Auth (Anonymous)
        if (snapshot.data == null) {
          // Trigger anonymous sign-in if not already in progress
          // logic is handled by AuthProvider or we can do it here safely
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthProvider>().signInAnonymously();
          });

          // Still show splash while generating the anonymous session
          return const MaterialApp(
            key: ValueKey('splash_anon'),
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        }

        // 3. User is authenticated (Anonymous or Linked) -> Show App
        return MaterialApp.router(
          key: const ValueKey('main_app'),
          title: 'SnapCal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: appRouter,
        );
      },
    );
  }
}
