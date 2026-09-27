import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/providers/calorie_budget_provider.dart';
import 'package:snapcal/widgets/motion/rolling_number.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/core/theme/app_theme.dart';
import 'package:snapcal/data/models/achievement.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/meal_template.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/models/water_log.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/data/repositories/water_repository.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/achievements_provider.dart';
import 'package:snapcal/providers/activity_provider.dart';
import 'package:snapcal/providers/connectivity_provider.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/providers/template_provider.dart';
import 'package:snapcal/providers/water_provider.dart';
import 'package:snapcal/screens/home/home_screen.dart';
import 'package:snapcal/screens/log/log_screen.dart';

String _today() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

List<Meal> _meals() {
  final n = DateTime.now();
  Meal m(String id, int h, String type, String name, int kcal) => Meal(
    id: id,
    timestamp: DateTime(n.year, n.month, n.day, h, 10).millisecondsSinceEpoch,
    dateString: _today(),
    foodName: name,
    calories: kcal,
    macros: Macros(protein: 30, carbs: 40, fat: 15),
    mealType: type,
    portion: '1 bowl',
  );
  return [
    m('b', 8, 'Breakfast', 'Avocado toast and eggs', 420),
    m('l', 13, 'Lunch', 'Chicken rice bowl', 610),
    m('s', 16, 'Snack', 'Greek yogurt and berries', 190),
  ];
}

class _Settings extends Settings {
  @override
  Future<UserSettings> build() async =>
      UserSettings.defaults().copyWith(isPro: true);
}

class _Achievements extends Achievements {
  @override
  Future<List<Achievement>> build() async => [];
  @override
  Future<void> refreshAchievements() async {}
}

/// Health Connect answers when a test says so, as on a phone a moment
/// after opening.
var _healthReady = Completer<void>();

class _Activity extends Activity {
  @override
  Future<ActivitySummary> build() async {
    await _healthReady.future;
    return const ActivitySummary(
      steps: 8240,
      activeCalories: 320,
      healthConnected: true,
    );
  }
}

class _Water extends Water {
  @override
  Future<WaterState> build() async =>
      const WaterState(todayTotal: 1600, goal: 2500);
}

class _Templates extends Templates {
  @override
  Future<List<MealTemplate>> build() async => const [];
}

class _MealLog extends MealLog {
  @override
  FutureOr<void> build() {}
}

class _MealRepo implements MealRepository {
  @override
  List<Meal> getMealsByDate(String dateString) =>
      dateString == _today() ? _meals() : const [];
  @override
  List<Meal> getAllMeals() => _meals();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _WaterRepo implements WaterRepository {
  @override
  List<WaterLog> getWaterByDate(String dateString) => const [];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _app(String initial) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/log', builder: (_, _) => const LogScreen()),
    ],
  );
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(_Settings.new),
      achievementsProvider.overrideWith(_Achievements.new),
      activityProvider.overrideWith(_Activity.new),
      waterProvider.overrideWith(_Water.new),
      stepGoalProvider.overrideWith((ref) async => 10000),
      proAccessProvider.overrideWithValue(const ProAccess(ProStatus.pro)),
      todaysMealsProvider.overrideWith((ref) => Stream.value(_meals())),
      templatesProvider.overrideWith(_Templates.new),
      mealLogProvider.overrideWith(_MealLog.new),
      mealRepositoryProvider.overrideWith((ref) async => _MealRepo()),
      waterRepositoryProvider.overrideWith((ref) async => _WaterRepo()),
      connectivityProvider.overrideWith(
        (ref) => Stream.value([ConnectivityResult.wifi]),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _wait(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The big "left" figure on Home.
int _heroLeft(WidgetTester tester) =>
    tester.widget<RollingNumber>(find.byType(RollingNumber).first).value;

CalorieBudget _budget(ProviderContainer c) => c.read(calorieBudgetProvider);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    _healthReady = Completer<void>();
    SharedPreferences.setMockInitialValues({});
  });

  group('the budget', () {
    ProviderContainer container({required bool pro}) {
      final c = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(_Settings.new),
          activityProvider.overrideWith(_Activity.new),
          proAccessProvider.overrideWithValue(
            ProAccess(pro ? ProStatus.pro : ProStatus.free),
          ),
          todaysMealsProvider.overrideWith((ref) => Stream.value(_meals())),
        ],
      );
      addTearDown(c.dispose);
      c.listen(calorieBudgetProvider, (_, _) {});
      return c;
    }

    test('free users keep the goal they set', () async {
      final c = container(pro: false);
      _healthReady.complete();
      await c.read(settingsProvider.future);
      await c.read(todaysMealsProvider.future);
      await c.read(activityProvider.future);
      expect(_budget(c).goal, 2000);
      expect(_budget(c).left, 780);
      expect(_budget(c).activityBonus, 0);
    });

    test("Pro adds the day's walking calories", () async {
      final c = container(pro: true);
      _healthReady.complete();
      await c.read(settingsProvider.future);
      await c.read(todaysMealsProvider.future);
      await c.read(activityProvider.future);
      expect(_budget(c).goal, 2320);
      expect(_budget(c).left, 1100);
      expect(_budget(c).activityBonus, 320);
    });

    test(
      "before the phone answers, Pro opens on today's remembered figure",
      () async {
        await ActivityBonusMemory.write(_today(), 300);
        final c = container(pro: true);
        await c.read(settingsProvider.future);
        await c.read(todaysMealsProvider.future);
        await c.read(rememberedActivityBonusProvider.future);
        expect(_budget(c).settled, isTrue);
        expect(_budget(c).goal, 2300);

        _healthReady.complete();
        await c.read(activityProvider.future);
        expect(_budget(c).goal, 2320);
      },
    );

    test('a figure remembered yesterday is not used today', () async {
      await ActivityBonusMemory.write('1999-01-01', 300);
      rememberedActivityWait = Duration.zero;
      addTearDown(() => rememberedActivityWait = const Duration(seconds: 2));
      final c = container(pro: true);
      await c.read(settingsProvider.future);
      await c.read(rememberedActivityBonusProvider.future);
      expect(_budget(c).activityBonus, 0);
    });
  });

  testWidgets('Home and the Food Log show the same calories left', (
    tester,
  ) async {
    _phone(tester);
    // Made here, in the test's own clock, so completing it is seen.
    _healthReady = Completer<void>()..complete();
    await tester.pumpWidget(_app('/'));
    await _wait(tester, 3000);
    expect(_heroLeft(tester), 1100);
    await tester.pumpWidget(const SizedBox.shrink());
    await _wait(tester, 1000);

    await tester.pumpWidget(_app('/log'));
    await _wait(tester, 3000);
    expect(find.textContaining('1,100 left'), findsOneWidget);
    expect(find.byKey(const ValueKey('log-activity-bonus')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await _wait(tester, 1000);
  });

  testWidgets('Home waits for the walking calories instead of jumping', (
    tester,
  ) async {
    _phone(tester);
    _healthReady = Completer<void>();
    await tester.pumpWidget(_app('/'));
    await _wait(tester, 1000);
    // Nothing remembered yet today and the phone hasn't answered: an
    // outline, not a figure that is about to jump.
    expect(find.byType(RollingNumber), findsNothing);
    _healthReady.complete();
    await _wait(tester, 3000);
    expect(_heroLeft(tester), 1100);
    await tester.pumpWidget(const SizedBox.shrink());
    await _wait(tester, 1000);
  });
}
