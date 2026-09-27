import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/water_provider.dart';
import 'package:snapcal/screens/home/widgets/activity_health_connect_sheet.dart';
import 'package:snapcal/screens/log/widgets/hydration_sheet.dart';
import 'package:snapcal/screens/sync/sync_data_screen.dart';

class _Water extends Water {
  _Water(this.start);

  final int start;

  @override
  Future<WaterState> build() async => WaterState(todayTotal: start, goal: 2000);

  @override
  Future<void> addWater(int ml) async {
    final now = state.valueOrNull ?? const WaterState(todayTotal: 0);
    state = AsyncData(now.copyWith(todayTotal: now.todayTotal + ml));
  }

  @override
  Future<void> removeWater(int ml) async {
    final now = state.valueOrNull ?? const WaterState(todayTotal: 0);
    state = AsyncData(now.copyWith(todayTotal: now.todayTotal - ml));
  }
}

/// Not connected until authorised; then reads 6,240 steps.
class _Activity extends Activity {
  static bool granted = false;

  @override
  Future<ActivitySummary> build() async =>
      granted
          ? const ActivitySummary(
            steps: 6240,
            activeCalories: 250,
            healthConnected: true,
          )
          : const ActivitySummary();

  @override
  Future<bool> authorize() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    granted = true;
    return true;
  }
}

Widget _opener(void Function(BuildContext) open, List<Override> overrides) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: TextButton(
                    onPressed: () => open(context),
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      ),
    );

Future<void> _run(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('water: the highlight slides, a glass floats its amount, and '
      'undo drains it back', (tester) async {
    await tester.pumpWidget(
      _opener(showHydrationSheet, [
        waterProvider.overrideWith(() => _Water(1000)),
      ]),
    );
    await tester.tap(find.text('open'));
    await _run(tester, 800);

    final highlight = find.byKey(const ValueKey('water-preset-highlight'));
    final before = tester.getTopLeft(highlight).dx;
    await tester.tap(find.text('500 ml'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final moving = tester.getTopLeft(highlight).dx;
    await _run(tester, 600);
    final after = tester.getTopLeft(highlight).dx;
    expect(moving, greaterThan(before));
    expect(after, greaterThan(moving), reason: 'it glides, not jumps');

    await tester.tap(find.text('Add 500 ml'));
    await tester.pump();
    await _run(tester, 300);
    expect(find.text('+500 ml'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    await _run(tester, 1500);

    await tester.tap(find.text('Undo'));
    await _run(tester, 1200);
    expect(find.text('1,000'), findsOneWidget);
    await _run(tester, 6000);
  });

  testWidgets('water: the glass that reaches the goal celebrates', (
    tester,
  ) async {
    await tester.pumpWidget(
      _opener(showHydrationSheet, [
        waterProvider.overrideWith(() => _Water(1750)),
      ]),
    );
    await tester.tap(find.text('open'));
    await _run(tester, 800);
    expect(find.byKey(const ValueKey('water-goal-chip')), findsNothing);
    await tester.tap(find.text('Add 250 ml'));
    await tester.pump();
    await _run(tester, 1200);
    expect(find.byKey(const ValueKey('water-goal-chip')), findsOneWidget);
    expect(find.text('Daily goal reached 🎉'), findsOneWidget);
    await _run(tester, 6500);
  });

  testWidgets('health connect links, then shows steps against the user goal', (
    tester,
  ) async {
    _Activity.granted = false;
    await tester.pumpWidget(
      _opener(showActivityHealthConnectSheet, [
        activityProvider.overrideWith(_Activity.new),
        stepGoalProvider.overrideWith((ref) async => 8000),
      ]),
    );
    await tester.tap(find.text('open'));
    await _run(tester, 800);
    expect(find.text('Not connected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hc-connect')));
    await tester.pump();
    await _run(tester, 200);
    expect(find.text('Checking…'), findsOneWidget);

    await _run(tester, 900);
    expect(find.byKey(const ValueKey('hc-linked')), findsOneWidget);

    await _run(tester, 2500);
    expect(find.text('78% of your 8,000 step goal'), findsOneWidget);
    expect(find.text('6,240'), findsOneWidget);
  });

  testWidgets('the backup screen draws in and offers its buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SyncDataScreen(),
        ),
      ),
    );
    await _run(tester, 3200);
    expect(find.text('Never lose your progress'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
