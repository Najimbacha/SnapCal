import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_motion.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'screens/home/home_screen.dart';
import 'screens/snap/snap_screen.dart';
import 'screens/log/log_screen.dart';
import 'screens/log/health_metric_detail_screen.dart';
import 'screens/log/models/log_metric_models.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/settings/account_screen.dart';
import 'screens/settings/body_profile_screen.dart';
import 'screens/settings/data_sync_screen.dart';
import 'screens/settings/nutrition_goals_screen.dart';
import 'screens/settings/preferences_screen.dart';
import 'screens/assistant/assistant_screen.dart';
import 'screens/home/activity_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/scan_choice_sheet.dart';
import 'providers/auth_state_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/planner/meal_planner_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'screens/paywall/pro_welcome_screen.dart';
import 'data/services/premium_conversion_service.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'widgets/hero_action_button.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/settings/fcm_debug_screen.dart';
import 'screens/voice/voice_meal_screen.dart';
import 'core/services/config_service.dart';
import 'widgets/motion/tab_switcher.dart';

part 'router.g.dart';

/// Global route observer for managing hardware lifecycle across screens
final RouteObserver<ModalRoute<dynamic>> routeObserver =
    RouteObserver<ModalRoute<dynamic>>();

/// Global router reference for callbacks outside widget tree (FCM, notifications)
GoRouter? globalRouter;

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(settingsProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;

  String? _redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authStateProvider).valueOrNull;
    final settings = _ref.read(settingsProvider).valueOrNull;
    final onboarding = state.matchedLocation == '/onboarding';
    final loggingIn = state.matchedLocation == '/auth';

    if (auth != null &&
        settings != null &&
        !settings.onboardingComplete &&
        !onboarding &&
        !loggingIn) {
      return '/onboarding';
    }
    // Signed in from onboarding's "I already have an account": home, where
    // a returning user belongs -- not Settings.
    if (loggingIn && auth != null && !auth.isAnonymous) {
      return '/';
    }
    // An account that has already done onboarding has no business in it.
    // Its settings can arrive a moment after sign-in; this lets them move
    // the user on instead of leaving them to answer again and overwrite
    // the account's plan.
    if (onboarding && settings != null && settings.onboardingComplete) {
      return '/';
    }
    return null;
  }
}

@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  final notifier = _RouterNotifier(ref);
  final router = GoRouter(
    initialLocation: '/',
    observers: [routeObserver],
    refreshListenable: notifier,
    redirect: notifier._redirect,
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const OnboardingFlowScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder:
            (context, state) => _sharedAxisPage(state, const AuthScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const SettingsScreen(showBack: true)),
      ),
      GoRoute(
        path: '/settings/body-profile',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const BodyProfileScreen()),
      ),
      GoRoute(
        path: '/settings/nutrition-goals',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const NutritionGoalsScreen()),
      ),
      GoRoute(
        path: '/settings/preferences',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const PreferencesScreen()),
      ),
      GoRoute(
        path: '/settings/account',
        pageBuilder:
            (context, state) => _sharedAxisPage(state, const AccountScreen()),
      ),
      GoRoute(
        path: '/settings/data-sync',
        pageBuilder:
            (context, state) => _sharedAxisPage(state, const DataSyncScreen()),
      ),
      GoRoute(
        path: '/settings/about',
        pageBuilder:
            (context, state) => _sharedAxisPage(state, const AboutScreen()),
      ),
      // Exposes the raw FCM token and message payloads — debug builds only (BUG-021).
      if (kDebugMode)
        GoRoute(
          path: '/settings/fcm-debug',
          pageBuilder:
              (context, state) =>
                  _sharedAxisPage(state, const FcmDebugScreen()),
        ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final limitReached = extra?['limitReached'] as bool? ?? false;
          final entryPoint = PremiumConversionService().parseEntryPoint(
            extra?['entryPoint'] as String?,
            limitReached: limitReached,
          );
          final featureName = extra?['featureName'] as String?;
          return _sharedAxisPage(
            state,
            PaywallScreen(
              limitReached: limitReached,
              entryPoint: entryPoint,
              featureName: featureName,
              automatic: extra?['automatic'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/pro-welcome',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _floodPage(
            state,
            ProWelcomeScreen(
              isRestore: extra?['restore'] as bool? ?? false,
              onContinue: () => context.go('/'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/progress',
        pageBuilder:
            (context, state) => _sharedAxisPage(state, const ProgressScreen()),
      ),
      GoRoute(
        path: '/assistant',
        pageBuilder:
            (context, state) => _sharedAxisPage(state, const AssistantScreen()),
      ),
      GoRoute(
        path: '/planner',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const MealPlannerScreen()),
      ),
      GoRoute(
        path: '/achievements',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const AchievementsScreen()),
      ),
      GoRoute(
        path: '/activity',
        pageBuilder:
            (context, state) => _sharedAxisPage(state, const ActivityScreen()),
      ),
      GoRoute(
        path: '/voice-log',
        pageBuilder:
            (context, state) => _sharedAxisPage(state, const VoiceMealScreen()),
      ),
      GoRoute(
        path: '/log/metric/:metric',
        pageBuilder: (context, state) {
          final metric = LogMetricType.fromId(state.pathParameters['metric']);
          return _sharedAxisPage(
            state,
            HealthMetricDetailScreen(metric: metric ?? LogMetricType.calories),
          );
        },
      ),
      StatefulShellRoute(
        builder:
            (context, state, navigationShell) =>
                MainShell(navigationShell: navigationShell),
        // Like the indexed stack, every tab stays alive; switching between
        // them glides instead of cutting. The camera (branch 2) only fades.
        navigatorContainerBuilder:
            (context, navigationShell, children) => TabSwitcher(
              currentIndex: navigationShell.currentIndex,
              fadeOnlyIndex: 2,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/log',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: LogScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/snap',
                pageBuilder: (context, state) {
                  final initialMode =
                      state.uri.queryParameters['mode'] == 'barcode'
                          ? SnapInitialMode.barcode
                          : SnapInitialMode.food;
                  return NoTransitionPage(
                    key: ValueKey(state.uri.toString()),
                    child: SnapScreen(initialMode: initialMode),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: ReportsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: SettingsScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  globalRouter = router;
  ref.onDispose(() {
    globalRouter = null;
    router.dispose();
    notifier.dispose();
  });
  return router;
}

CustomTransitionPage<void> _sharedAxisPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.scaled,
        fillColor: Theme.of(context).colorScheme.surface,
        child: child,
      );
    },
  );
}

/// Green floods up from the buy button at the bottom of the screen, then
/// clears to show the page underneath: the welcome after paying for Pro.
CustomTransitionPage<void> _floodPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (AppMotion.reduceMotion(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final t = animation.value;
          final grow = Curves.easeInOutCubic.transform(
            (t / .6).clamp(0.0, 1.0),
          );
          final clear = Curves.easeOut.transform(
            ((t - .55) / .45).clamp(0.0, 1.0),
          );
          return ClipPath(
            clipper: _CircleFromBottom(grow),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                child!,
                if (clear < 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: AppColors.primary.withValues(alpha: 1 - clear),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _CircleFromBottom extends CustomClipper<Path> {
  const _CircleFromBottom(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final origin = Offset(size.width / 2, size.height - 60);
    final reach = Offset(size.width / 2, size.height).distance + 60;
    return Path()
      ..addOval(Rect.fromCircle(center: origin, radius: reach * progress));
  }

  @override
  bool shouldReclip(_CircleFromBottom old) => old.progress != progress;
}

/// Shell route for bottom navigation
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _lastNonSnapBranch = 0;

  int _branchToNav(int branchIndex) {
    if (branchIndex < 2) return branchIndex;
    if (branchIndex == 2) return _branchToNav(_lastNonSnapBranch);
    return branchIndex - 1;
  }

  int _navToBranch(int navIndex) {
    if (navIndex < 2) return navIndex;
    return navIndex + 1;
  }

  @override
  Widget build(BuildContext context) {
    final currentBranch = widget.navigationShell.currentIndex;
    if (currentBranch != 2) _lastNonSnapBranch = currentBranch;

    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      floatingActionButton:
          currentBranch == 2
              ? null
              : Transform.translate(
                offset: const Offset(0, 28),
                child: HeroActionButton(
                  isActive: false,
                  onTap: () {
                    showScanChoiceSheet(
                      context: context,
                      onFoodScan: () => context.go('/snap'),
                      onBarcodeScan: () => context.go('/snap?mode=barcode'),
                      onVoiceLog:
                          ConfigService().voiceLoggingEnabled
                              ? () => context.push('/voice-log')
                              : null,
                    );
                  },
                ),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar:
          currentBranch == 2
              ? const SizedBox.shrink()
              : BottomNavBar(
                currentIndex: _branchToNav(currentBranch),
                onTap: (index) {
                  HapticFeedback.selectionClick();
                  final branchIndex = _navToBranch(index);
                  widget.navigationShell.goBranch(
                    branchIndex,
                    initialLocation:
                        branchIndex == widget.navigationShell.currentIndex,
                  );
                  if (mounted) setState(() {});
                },
              ),
    );
  }
}
