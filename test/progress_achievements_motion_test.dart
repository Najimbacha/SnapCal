import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/data/models/body_metric.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/achievements_provider.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/auth_state_provider.dart';
import 'package:snapcal/providers/metrics_provider.dart';
import 'package:snapcal/providers/promo_offer_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/achievements/widgets/badge_card.dart';
import 'package:snapcal/screens/achievements/widgets/badge_celebration.dart';
import 'package:snapcal/screens/achievements/widgets/badge_detail_sheet.dart';
import 'package:snapcal/screens/progress/widgets/weight_trend_chart.dart';
import 'package:snapcal/screens/settings/settings_screen.dart';

final _weights = [81.2, 80.6, 80.9, 79.8, 79.4, 79.6, 78.8, 78.3];

/// Newest first, as the provider keeps them.
List<BodyMetric> _metrics(List<double> weights) => [
  for (var i = weights.length - 1; i >= 0; i--)
    BodyMetric(
      id: 'w$i',
      date: DateTime(2026, 8, 7).add(Duration(days: 7 * i)),
      weight: weights[i],
    ),
];

Achievement _badge({
  String id = 'iron_will',
  int progress = 18,
  int target = 30,
  bool unlocked = false,
}) => Achievement(
  id: id,
  titleKey: 'achievement_$id',
  descriptionKey: 'achievement_${id}_desc',
  emoji: '⚡',
  categoryIndex: 0,
  targetValue: target,
  currentProgress: progress,
  isUnlocked: unlocked,
  unlockedAt: unlocked ? DateTime(2026, 9, 21).millisecondsSinceEpoch : null,
);

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

class _FakeSettings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _FakeActivity extends Activity {
  @override
  Future<ActivitySummary> build() async => ActivitySummary();
}

class _FakeMetrics extends BodyMetrics {
  @override
  Future<List<BodyMetric>> build() async => _metrics(_weights);
}

class _FakeAchievements extends Achievements {
  @override
  Future<List<Achievement>> build() async => [
    _badge(id: 'first_flame', progress: 1, target: 1, unlocked: true),
    _badge(id: 'bullseye', progress: 1, target: 1, unlocked: true),
    _badge(),
  ];
}

void main() {
  group('Profile', () {
    testWidgets('leads to Progress and Achievements', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SettingsScreen()),
          GoRoute(
            path: '/progress',
            builder: (_, _) => const Text('PROGRESS SCREEN'),
          ),
          GoRoute(
            path: '/achievements',
            builder: (_, _) => const Text('ACHIEVEMENTS SCREEN'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            settingsProvider.overrideWith(() => _FakeSettings()),
            activityProvider.overrideWith(() => _FakeActivity()),
            promoOfferProvider.overrideWith((ref) async => null),
            bodyMetricsProvider.overrideWith(() => _FakeMetrics()),
            achievementsProvider.overrideWith(() => _FakeAchievements()),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('YOUR JOURNEY'), findsOneWidget);
      expect(find.text('78.3 kg'), findsOneWidget);
      expect(find.text('2 of 3 earned'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settings-progress')));
      await tester.pumpAndSettle();
      expect(find.text('PROGRESS SCREEN'), findsOneWidget);

      router.go('/');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-achievements')));
      await tester.pumpAndSettle();
      expect(find.text('ACHIEVEMENTS SCREEN'), findsOneWidget);
    });
  });

  group('weight line', () {
    Widget chart(List<double> weights) => _app(
      Center(
        child: SizedBox(
          width: 360,
          child: WeightTrendChart(metrics: _metrics(weights)),
        ),
      ),
    );

    testWidgets('rolls up to the latest weight', (tester) async {
      await tester.pumpWidget(chart(_weights));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('78.3 kg'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('78.3 kg'), findsOneWidget);
      expect(find.text('−2.9 kg since Aug 7'), findsOneWidget);
    });

    testWidgets('a finger on the line shows that weigh-in', (tester) async {
      await tester.pumpWidget(chart(_weights));
      await tester.pumpAndSettle();
      // What is actually painted, not just what it is heading for.
      double bubble() =>
          tester
              .renderObject<RenderAnimatedOpacity>(
                find.ancestor(
                  of: find.byKey(const ValueKey('weight-bubble')),
                  matching: find.byType(AnimatedOpacity),
                ),
              )
              .opacity
              .value;
      expect(bubble(), 0);

      final paint = find.byKey(const ValueKey('weight-trend-paint'));
      final gesture = await tester.startGesture(tester.getTopLeft(paint));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(bubble(), 1);
      expect(find.text('81.2 kg'), findsOneWidget);
      expect(find.text('Aug 7'), findsNWidgets(2));

      // A finger slides in many small steps.
      final width = tester.getSize(paint).width;
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(Offset((width - 2) / 20, 0));
        await tester.pump();
      }
      expect(find.text('Sep 25'), findsNWidgets(2));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(bubble(), 0);
    });

    testWidgets('a new weigh-in stretches the line to it', (tester) async {
      await tester.pumpWidget(chart(_weights));
      await tester.pumpAndSettle();
      await tester.pumpWidget(chart([..._weights, 77.9]));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('77.9 kg'), findsOneWidget);
      expect(find.text('−3.3 kg since Aug 7'), findsOneWidget);
    });
  });

  group('badges', () {
    testWidgets('an earned badge waits, then turns over to gold', (
      tester,
    ) async {
      final badge = _badge(
        id: 'precision_pro',
        progress: 7,
        target: 7,
        unlocked: true,
      );
      Widget card(bool pending) => _app(
        Center(
          child: SizedBox(
            width: 170,
            height: 200,
            child: BadgeCard(achievement: badge, pending: pending),
          ),
        ),
      );
      await tester.pumpWidget(card(true));
      await tester.pumpAndSettle();
      expect(find.text('Unlocked'), findsNothing);
      expect(find.text('7 / 7'), findsOneWidget);

      await tester.pumpWidget(card(false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      // Mid-turn the old face is still showing, edge-on.
      expect(find.text('7 / 7'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Unlocked'), findsOneWidget);
      expect(find.text('7 / 7'), findsNothing);
    });

    testWidgets('a closer look fills the ring to how far along it is', (
      tester,
    ) async {
      await tester.pumpWidget(_app(BadgeDetailSheet(achievement: _badge())));
      double ring() =>
          tester
              .widget<CircularProgressIndicator>(
                find.byKey(const ValueKey('badge-detail-ring')),
              )
              .value!;
      await tester.pump(const Duration(milliseconds: 200));
      expect(ring(), greaterThan(0));
      expect(ring(), lessThan(0.6));
      await tester.pumpAndSettle();
      expect(ring(), closeTo(0.6, 1e-9));
      expect(find.text('18'), findsOneWidget);
      expect(find.text('12 to go'), findsOneWidget);
    });

    testWidgets('an earned badge is celebrated and handed back', (
      tester,
    ) async {
      final badge = _badge(
        id: 'precision_pro',
        progress: 7,
        target: 7,
        unlocked: true,
      );
      var done = false;
      await tester.pumpWidget(
        _app(
          Builder(
            builder:
                (context) => Column(
                  children: [
                    SizedBox(
                      width: 170,
                      height: 200,
                      child: BadgeCard(achievement: badge, pending: true),
                    ),
                    TextButton(
                      onPressed: () async {
                        await celebrateBadge(context, badge);
                        done = true;
                      },
                      child: const Text('go'),
                    ),
                  ],
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('ACHIEVEMENT UNLOCKED!'), findsOneWidget);
      expect(find.text('Precision Pro'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byKey(const ValueKey('badge-celebration-done')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(done, isTrue);
      expect(find.text('ACHIEVEMENT UNLOCKED!'), findsNothing);
    });
  });
}
