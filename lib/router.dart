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
import 'widgets/hero_action_button.dart';

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
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _lastNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateNavIndex();
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateNavIndex();
  }

  void _updateNavIndex() {
    final mapped = _mapBranchToNav(widget.navigationShell.currentIndex);
    if (mapped != -1) {
      _lastNavIndex = mapped;
    }
  }

  int _mapBranchToNav(int branchIndex) {
    if (branchIndex < 2) return branchIndex;
    if (branchIndex == 2) return -1; // Snap is FAB
    return branchIndex - 1;
  }

  int _mapNavToBranch(int navIndex) {
    if (navIndex < 2) return navIndex;
    return navIndex + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      floatingActionButton: HeroActionButton(
        isActive: widget.navigationShell.currentIndex == 2,
        onTap: () {
          widget.navigationShell.goBranch(
            2,
            initialLocation: widget.navigationShell.currentIndex == 2,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _lastNavIndex,
        onTap: (index) {
          final branchIndex = _mapNavToBranch(index);
          widget.navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
