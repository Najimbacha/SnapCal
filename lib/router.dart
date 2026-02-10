import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/snap/snap_screen.dart';
import 'screens/log/log_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/assistant/assistant_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/planner/meal_planner_screen.dart';
import 'screens/paywall/paywall_screen.dart'; // Import
import 'screens/onboarding/onboarding_screen.dart';

/// App router configuration
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final loggingIn = state.matchedLocation == '/auth';
    final onboarding = state.matchedLocation == '/onboarding';

    // 1. Auth blocking (optional, but SnapCal allows anon access)
    if (authProvider.isAuthenticated &&
        !authProvider.isAnonymous &&
        loggingIn) {
      return '/';
    }

    // 2. Onboarding Redirect
    // If auth is initialized (even anon) and onboarding not complete,
    // and they aren't already on the onboarding screen, send them there.
    if (authProvider.isAuthenticated &&
        !settingsProvider.onboardingComplete &&
        !onboarding &&
        !loggingIn) {
      return '/onboarding';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/paywall', // New Route
      builder: (context, state) => const PaywallScreen(),
    ),
    GoRoute(
      path: '/assistant',
      builder: (context, state) => const AssistantScreen(),
    ),
    GoRoute(
      path: '/planner',
      builder: (context, state) => const MealPlannerScreen(),
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
              pageBuilder:
                  (context, state) =>
                      const NoTransitionPage(child: SnapScreen()),
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

/// Shell route for bottom navigation
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
