import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';
import 'screens/home/home_screen.dart';
import 'screens/snap/snap_screen.dart';
import 'screens/log/log_screen.dart';
import 'screens/log/health_metric_detail_screen.dart';
import 'screens/log/models/log_metric_models.dart';
import 'screens/log/water_tracker_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/assistant/assistant_screen.dart';
import 'screens/home/activity_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/scan_choice_sheet.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/planner/meal_planner_screen.dart';
import 'screens/paywall/paywall_screen.dart'; // Import
import 'data/services/premium_conversion_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/progress/progress_screen.dart'; // Import
import 'widgets/hero_action_button.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/insights/weekly_wrap_screen.dart';

/// Global route observer for managing hardware lifecycle across screens
final RouteObserver<ModalRoute<dynamic>> routeObserver =
    RouteObserver<ModalRoute<dynamic>>();

/// Factory function to create a reactive router
GoRouter createRouter(AuthProvider auth, SettingsProvider settings) {
  return GoRouter(
    initialLocation: '/',
    observers: [routeObserver],
    refreshListenable: Listenable.merge([auth, settings]),
    redirect: (context, state) {
      final onboarding = state.matchedLocation == '/onboarding';
      final loggingIn = state.matchedLocation == '/auth';

      // 1. Onboarding Redirect: Send to /onboarding if not complete (Full Users Only)
      if (auth.isAuthenticated &&
          !auth.isAnonymous &&
          !settings.onboardingComplete &&
          !onboarding &&
          !loggingIn) {
        return '/onboarding';
      }

      // 2. Auth Redirect: Kick out of /auth if logged in as a full user
      if (loggingIn && auth.isAuthenticated && !auth.isAnonymous) {
        return '/settings';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const OnboardingScreen()),
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
        path: '/insights',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const WeeklyWrapScreen()),
      ),
      GoRoute(
        path: '/activity',
        pageBuilder:
            (context, state) => _sharedAxisPage(state, const ActivityScreen()),
      ),
      GoRoute(
        path: '/water',
        pageBuilder:
            (context, state) =>
                _sharedAxisPage(state, const WaterTrackerScreen()),
      ),
      GoRoute(
        path: '/log/metric/:metric',
        pageBuilder: (context, state) {
          final metric = LogMetricType.fromId(state.pathParameters['metric']);
          if (metric == LogMetricType.water) {
            return _sharedAxisPage(state, const WaterTrackerScreen());
          }
          return _sharedAxisPage(
            state,
            HealthMetricDetailScreen(metric: metric ?? LogMetricType.calories),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
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

/// Shell route for bottom navigation
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Tracks the last non-snap branch so the nav bar doesn't lose highlighting
  /// when the user is on the Snap (camera) screen.
  int _lastNonSnapBranch = 0;

  /// Maps branch index (0-4) to bottom nav index (0-3).
  /// Snap (branch 2) is not in the nav bar — preserve last non-snap tab.
  int _branchToNav(int branchIndex) {
    if (branchIndex < 2) return branchIndex; // Home(0)→0, Log(1)→1
    if (branchIndex == 2) {
      return _branchToNav(_lastNonSnapBranch); // Snap → preserve
    }
    return branchIndex - 1; // Reports(3)→2, Profile(4)→3
  }

  /// Maps bottom nav index (0-3) to branch index (skipping Snap at index 2).
  int _navToBranch(int navIndex) {
    if (navIndex < 2) return navIndex; // Home(0)→0, Log(1)→1
    return navIndex + 1; // Reports(2)→3, Profile(3)→4
  }

  @override
  Widget build(BuildContext context) {
    final currentBranch = widget.navigationShell.currentIndex;
    if (currentBranch != 2) {
      _lastNonSnapBranch = currentBranch;
    }

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
