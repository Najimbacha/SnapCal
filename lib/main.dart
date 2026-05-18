import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';
import 'core/services/app_initializer.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'providers/water_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/widget_sync_provider.dart';
import 'providers/template_provider.dart';
import 'providers/achievements_provider.dart';
import 'providers/insights_provider.dart';
import 'data/services/connectivity_service.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🏗️ MAIN: Starting App...');
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
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 SnapCalApp: Initializing State...');
    // 1. Create instances immediately (sync)
    _mealRepository = MealRepository();
    _settingsRepository = SettingsRepository();
    _waterRepository = WaterRepository();
    _assistantRepository = AssistantRepository();
    _aiService = AIService();

    // 2. Start Async Initialization
    _initialize();
  }

  void _initialize() {
    debugPrint('🎬 SnapCalApp: Starting _initialize()...');
    setState(() {
      _initFuture = AppInitializer.init(
            mealRepository: _mealRepository,
            settingsRepository: _settingsRepository,
            waterRepository: _waterRepository,
            assistantRepository: _assistantRepository,
          )
          .timeout(
            const Duration(
              seconds: 35,
            ), // Safety Hatch: transition to Error/Retry screen if initialization hangs for over 35 seconds
            onTimeout: () {
              debugPrint('❌ SnapCalApp: Initialization Timed Out!');
              throw TimeoutException(
                'Initialization timed out. Please check your internet connection or restart the app.',
              );
            },
          )
          .then((_) {
            debugPrint('✅ SnapCalApp: Initialization Complete');
          })
          .catchError((e) {
            debugPrint('❌ SnapCalApp: Initialization Error: $e');
            throw e;
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set up Global Error Boundary
    ErrorWidget.builder = (details) => _GlobalErrorView(details: details);

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // Show Splash while initializing
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }

        // Handle Initialization Errors (Network, Storage, etc.)
        if (snapshot.hasError) {
          final l10n = _startupLocalizations();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: Colors.orangeAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.startup_launch_issue,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        snapshot.error is TimeoutException
                            ? l10n.startup_initialization_slow
                            : l10n.startup_setup_failed,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _initialize,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(LucideIcons.refreshCw, size: 18),
                        label: Text(l10n.startup_retry_launch),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
            Provider<WaterRepository>.value(value: _waterRepository),
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
            ChangeNotifierProxyProvider<MetricsProvider, ActivityProvider>(
              create: (context) => ActivityProvider(),
              update:
                  (context, metrics, activity) =>
                      activity!..updateWeight(metrics.currentWeight),
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
            ProxyProvider3<
              MealProvider,
              SettingsProvider,
              ActivityProvider,
              WidgetSyncProvider
            >(
              update:
                  (context, meal, settings, activity, previous) =>
                      previous ?? WidgetSyncProvider(meal, settings, activity),
              dispose: (context, sync) => sync.dispose(),
            ),
            ChangeNotifierProvider(create: (_) => TemplateProvider()..init()),
            ChangeNotifierProvider(
              create: (_) => AchievementsProvider()..init(),
            ),
            ChangeNotifierProvider(create: (_) => InsightsProvider()),
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
                  title: AppLocalizations.of(context)?.appTitle ?? 'SnapCal',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme.copyWith(
                    colorScheme:
                        lightDynamic ?? AppTheme.lightTheme.colorScheme,
                  ),
                  darkTheme: AppTheme.darkTheme.copyWith(
                    colorScheme: darkDynamic ?? AppTheme.darkTheme.colorScheme,
                  ),
                  themeMode: _getThemeMode(settingsProvider.themeMode),
                  routerConfig: _router,
                  locale: Locale(settingsProvider.languageCode),
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en'), // English
                    Locale('ar'), // Arabic
                    Locale('es'), // Spanish
                    Locale('fr'), // French
                  ],
                  builder: (context, child) {
                    // 1. Handle Initial/Loading state
                    final isBootstrapping = auth.status == AuthStatus.initial;

                    // Trigger anonymous sign-in if completely unauthenticated
                    if ((isBootstrapping ||
                            auth.status == AuthStatus.unauthenticated ||
                            auth.status == AuthStatus.error) &&
                        auth.user == null &&
                        !auth.isBusy) {
                      // Use a zero-delay future to move the side-effect out of the build method
                      Future.delayed(
                        Duration.zero,
                        () => auth.signInAnonymously(),
                      );
                    }

                    // Normal app flow: local data remains usable while auth warms up
                    // or retries silently in the background.
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
    final l10n = _startupLocalizations();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
                  child: const Icon(
                    Icons.report_problem_rounded,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.startup_initialization_error,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.startup_error_body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    l10n.startup_reload,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

AppLocalizations _startupLocalizations() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final languageCode =
      AppLocalizations.supportedLocales.any(
            (supported) => supported.languageCode == locale.languageCode,
          )
          ? locale.languageCode
          : 'en';
  return lookupAppLocalizations(Locale(languageCode));
}
