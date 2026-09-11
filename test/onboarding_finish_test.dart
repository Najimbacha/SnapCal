import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/data/models/body_metric.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/services/calorie_onboarding_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/auth_state_provider.dart';
import 'package:snapcal/providers/metrics_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/onboarding/onboarding_flow_screen.dart';

class _FakeSettings extends Settings {
  OnboardingRecommendation? saved;

  @override
  Future<UserSettings> build() async => UserSettings.defaults();

  @override
  Future<void> completeOnboarding({
    required OnboardingProfileInput profile,
    required OnboardingRecommendation recommendation,
  }) async {
    saved = recommendation;
    state = AsyncData(
      (state.valueOrNull ?? UserSettings.defaults()).copyWith(
        onboardingComplete: true,
        dailyCalorieGoal: recommendation.dailyCalories,
      ),
    );
  }
}

class _FakeBodyMetrics extends BodyMetrics {
  final weights = <double>[];

  @override
  Future<List<BodyMetric>> build() async => const [];

  @override
  Future<void> logWeight(
    double weightKg, {
    DateTime? date,
    double? heightCm,
    double? bodyFat,
  }) async {
    weights.add(weightKg);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('"Start plan" saves the plan and lands on Home', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = _FakeSettings();
    final metrics = _FakeBodyMetrics();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingFlowScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('HOME')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAnonymousProvider.overrideWithValue(true),
          settingsProvider.overrideWith(() => settings),
          bodyMetricsProvider.overrideWith(() => metrics),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    Future<void> settle([int ms = 1200]) async {
      for (var i = 0; i < ms ~/ 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> tapOn(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await settle();
    }

    final next = find.byKey(const ValueKey('onboarding-continue'));
    await settle(1500);
    await tapOn(find.byKey(const ValueKey('onboarding-get-started')));
    await tapOn(find.text(l10n.onboarding_goal_lose));
    await tapOn(next);
    await tapOn(find.text(l10n.onboarding_male));
    await tapOn(next);
    await tapOn(find.text(l10n.onboarding_pace_balanced));
    await tapOn(next);
    await tapOn(find.text(l10n.onboarding_activity_light));
    await tapOn(next);

    await tapOn(find.byKey(const ValueKey('onboarding-start-plan')));

    expect(find.text('HOME'), findsOneWidget);
    expect(find.byType(OnboardingFlowScreen), findsNothing);
    expect(settings.saved, isNotNull);
    expect(settings.state.valueOrNull?.onboardingComplete, isTrue);
    expect(metrics.weights, [75]);

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(2000);
  });
}
