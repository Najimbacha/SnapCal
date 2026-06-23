import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';
import 'core/services/app_initializer.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/services/fcm_service.dart';
import 'data/services/notification_service.dart';
import 'providers/auth_state_provider.dart';
import 'providers/auth_notifier_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🏗️ MAIN: Starting App...');
  await AppInitializer.preInit();
  GoogleFonts.dmSans();
  await GoogleFonts.pendingFonts();
  runApp(const ProviderScope(child: SnapCalApp()));
}

class SnapCalApp extends StatelessWidget {
  const SnapCalApp({super.key});

  @override
  Widget build(BuildContext context) => const AppInitializerGate();
}

class AppInitializerGate extends ConsumerStatefulWidget {
  const AppInitializerGate({super.key});

  @override
  ConsumerState<AppInitializerGate> createState() => _AppInitializerGateState();
}

class _AppInitializerGateState extends ConsumerState<AppInitializerGate> {
  late Future<void> _initFuture;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _runInit();
  }

  void _runInit() {
    _initFuture = AppInitializer.init().timeout(
      const Duration(seconds: 35),
      onTimeout: () => throw TimeoutException('Initialization timed out. Please check your internet connection or restart the app.'),
    ).then((_) {
      debugPrint('✅ SnapCalApp: Initialization Complete');
      _initialized = true;
    }).catchError((e) {
      debugPrint('❌ SnapCalApp: Initialization Error: $e');
      throw e;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SplashScreen(),
          );
        }

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
                      Icon(LucideIcons.alertCircle, color: Colors.orangeAccent, size: 64),
                      const SizedBox(height: 24),
                      Text(l10n.startup_launch_issue, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 12),
                      Text(snapshot.error is TimeoutException ? l10n.startup_initialization_slow : l10n.startup_setup_failed, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _runInit,
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                        icon: Icon(LucideIcons.refreshCw, size: 18),
                        label: Text(l10n.startup_retry_launch),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return const AppTree();
      },
    );
  }
}

class AppTree extends ConsumerWidget {
  const AppTree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (prev, next) {
      if (next.valueOrNull == null && next.hasValue) {
        Future.microtask(() => ref.read(authNotifierProvider.notifier).signInAnonymously());
      }
    });

    final router = ref.watch(routerProvider);

    // FCM + notification tap routing via global router
    FcmService().onFoodReminderTapped = () => globalRouter?.go('/snap');
    NotificationService.onFoodReminderTapped = () => globalRouter?.go('/snap');

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final settingsAsync = ref.watch(settingsProvider);
        if (!settingsAsync.hasValue) return const SizedBox.shrink();
        final settings = settingsAsync.requireValue;

        return MaterialApp.router(
          title: AppLocalizations.of(context)?.appTitle ?? 'SnapCal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme.copyWith(colorScheme: lightDynamic ?? AppTheme.lightTheme.colorScheme),
          darkTheme: AppTheme.darkTheme.copyWith(colorScheme: darkDynamic ?? AppTheme.darkTheme.colorScheme),
          themeMode: _getThemeMode(settings.themeMode),
          routerConfig: router,
          locale: Locale(settings.languageCode ?? 'en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar'), Locale('es'), Locale('fr')],
        );
      },
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}

AppLocalizations _startupLocalizations() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final languageCode = AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode) ? locale.languageCode : 'en';
  return lookupAppLocalizations(Locale(languageCode));
}

