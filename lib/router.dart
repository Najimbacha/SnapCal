import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
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
import 'screens/assistant/assistant_screen.dart';
import 'screens/home/activity_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/scan_choice_sheet.dart';
import 'providers/auth_state_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/planner/meal_planner_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'data/services/premium_conversion_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'widgets/hero_action_button.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/insights/weekly_wrap_screen.dart';
import 'screens/settings/fcm_debug_screen.dart';

part 'router.g.dart';

/// Global route observer for managing hardware lifecycle across screens
final RouteObserver<ModalRoute<dynamic>> routeObserver =
    RouteObserver<ModalRoute<dynamic>>();

/// Global router reference for callbacks outside widget tree (FCM, notifications)
GoRouter? globalRouter;

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(settingsProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;

  String? _redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authStateProvider).valueOrNull;
    final settings = _ref.read(settingsProvider).valueOrNull;
    final onboarding = state.matchedLocation == '/onboarding';
    final loggingIn = state.matchedLocation == '/auth';

    if (auth != null && !auth.isAnonymous && settings != null && !settings.onboardingComplete && !onboarding && !loggingIn) {
      return '/onboarding';
    }
    if (loggingIn && auth != null && !auth.isAnonymous) {
      return '/settings';
    }
    return null;
  }

  @override
  void dispose() { super.dispose(); }
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
      GoRoute(path: '/onboarding', pageBuilder: (context, state) => _sharedAxisPage(state, const OnboardingScreen())),
      GoRoute(path: '/auth', pageBuilder: (context, state) => _sharedAxisPage(state, const AuthScreen())),
      GoRoute(path: '/settings', pageBuilder: (context, state) => _sharedAxisPage(state, const SettingsScreen(showBack: true))),
      GoRoute(path: '/settings/fcm-debug', pageBuilder: (context, state) => _sharedAxisPage(state, const FcmDebugScreen())),
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final limitReached = extra?['limitReached'] as bool? ?? false;
          final entryPoint = PremiumConversionService().parseEntryPoint(extra?['entryPoint'] as String?, limitReached: limitReached);
          final featureName = extra?['featureName'] as String?;
          return _sharedAxisPage(state, PaywallScreen(limitReached: limitReached, entryPoint: entryPoint, featureName: featureName));
        },
      ),
      GoRoute(path: '/progress', pageBuilder: (context, state) => _sharedAxisPage(state, const ProgressScreen())),
      GoRoute(path: '/assistant', pageBuilder: (context, state) => _sharedAxisPage(state, const AssistantScreen())),
      GoRoute(path: '/planner', pageBuilder: (context, state) => _sharedAxisPage(state, const MealPlannerScreen())),
      GoRoute(path: '/achievements', pageBuilder: (context, state) => _sharedAxisPage(state, const AchievementsScreen())),
      GoRoute(path: '/insights', pageBuilder: (context, state) => _sharedAxisPage(state, const WeeklyWrapScreen())),
      GoRoute(path: '/activity', pageBuilder: (context, state) => _sharedAxisPage(state, const ActivityScreen())),
      GoRoute(
        path: '/log/metric/:metric',
        pageBuilder: (context, state) {
          final metric = LogMetricType.fromId(state.pathParameters['metric']);
          return _sharedAxisPage(state, HealthMetricDetailScreen(metric: metric ?? LogMetricType.calories));
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()))]),
          StatefulShellBranch(routes: [GoRoute(path: '/log', pageBuilder: (context, state) => const NoTransitionPage(child: LogScreen()))]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/snap',
              pageBuilder: (context, state) {
                final initialMode = state.uri.queryParameters['mode'] == 'barcode' ? SnapInitialMode.barcode : SnapInitialMode.food;
                return NoTransitionPage(key: ValueKey(state.uri.toString()), child: SnapScreen(initialMode: initialMode));
              },
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/reports', pageBuilder: (context, state) => const NoTransitionPage(child: ReportsScreen()))]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()))]),
        ],
      ),
    ],
  );
  globalRouter = router;
  ref.onDispose(() { globalRouter = null; router.dispose(); notifier.dispose(); });
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
        animation: animation, secondaryAnimation: secondaryAnimation,
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
      floatingActionButton: currentBranch == 2 ? null
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
      bottomNavigationBar: currentBranch == 2 ? const SizedBox.shrink()
          : BottomNavBar(
              currentIndex: _branchToNav(currentBranch),
              onTap: (index) {
                HapticFeedback.selectionClick();
                final branchIndex = _navToBranch(index);
                widget.navigationShell.goBranch(branchIndex, initialLocation: branchIndex == widget.navigationShell.currentIndex);
                if (mounted) setState(() {});
              },
            ),
    );
  }
}
