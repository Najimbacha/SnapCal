import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/core/state/async_ui_state.dart';
import 'package:snapcal/data/models/grocery_item.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/meal_plan.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/services/connectivity_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/planner_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/planner/meal_planner_screen.dart';
import 'package:snapcal/screens/planner/widgets/meal_card.dart';

void main() {
  testWidgets('minimal meal row shows essentials and expands details', (
    tester,
  ) async {
    final meal = _meal(
      id: 'breakfast',
      name: 'Greek yogurt bowl',
      type: 'Breakfast',
      ingredients: ['Greek yogurt', 'Blueberries'],
      rationale: 'High protein start.',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MealCard(meal: meal, onLogMeal: () {})),
      ),
    );

    expect(find.text('Greek yogurt bowl'), findsOneWidget);
    expect(find.text('420 kcal'), findsOneWidget);
    expect(find.text('PRO'), findsNothing);
    expect(find.text('32g'), findsNothing);

    await tester.tap(find.text('Greek yogurt bowl'));
    await tester.pumpAndSettle();

    expect(find.text('PRO'), findsOneWidget);
    expect(find.text('32g'), findsOneWidget);
    expect(find.text('Greek yogurt, Blueberries'), findsOneWidget);
  });

  testWidgets('planner renders full week and opens grocery sheet', (
    tester,
  ) async {
    final planner = FakePlannerProvider(_fullWeekPlan());
    final settings = FakeSettingsProvider(isPro: true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlannerProvider>.value(value: planner),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<ConnectivityService>.value(
            value: FakeConnectivityService(),
          ),
        ],
        child: _plannerApp(),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 7; i++) {
      expect(find.byKey(ValueKey('planner-day-$i')), findsOneWidget);
    }
    expect(find.text('Meal 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('planner-day-6')));
    await tester.pumpAndSettle();

    expect(find.text('Meal 7'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('planner-grocery-button')));
    await tester.pumpAndSettle();

    expect(find.text('Grocery List'), findsWidgets);
    expect(find.text('Oats'), findsOneWidget);
  });

  testWidgets('planner empty state keeps one primary CTA', (tester) async {
    final planner = FakePlannerProvider(null);
    final settings = FakeSettingsProvider(isPro: true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlannerProvider>.value(value: planner),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<ConnectivityService>.value(
            value: FakeConnectivityService(),
          ),
        ],
        child: _plannerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('planner-empty-generate')),
      findsOneWidget,
    );
    expect(find.text('Generate My Plan'), findsOneWidget);
  });
}

Widget _plannerApp() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MealPlannerScreen(),
      ),
      GoRoute(
        path: '/assistant',
        builder: (context, state) => const Scaffold(body: Text('Assistant')),
      ),
    ],
  );

  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

MealPlan _fullWeekPlan() {
  final start = DateTime.now();
  return MealPlan(
    id: 'plan-1',
    startDate: DateTime(start.year, start.month, start.day),
    endDate: DateTime(
      start.year,
      start.month,
      start.day,
    ).add(const Duration(days: 6)),
    weeklyMeals: {
      for (var day = 0; day < 7; day++)
        day: [
          _meal(
            id: 'meal-$day',
            name: 'Meal ${day + 1}',
            type: day == 0 ? 'Breakfast' : 'Lunch',
          ),
        ],
    },
  );
}

Meal _meal({
  required String id,
  required String name,
  required String type,
  List<String>? ingredients,
  String? rationale,
}) {
  return Meal(
    id: id,
    timestamp: DateTime(2026, 5, 25, 8).millisecondsSinceEpoch,
    dateString: '2026-05-25',
    foodName: name,
    calories: 420,
    macros: Macros(protein: 32, carbs: 44, fat: 12),
    mealType: type,
    prepTimeMins: 10,
    ingredients: ingredients,
    aiRationale: rationale,
  );
}

class FakePlannerProvider extends ChangeNotifier implements PlannerProvider {
  FakePlannerProvider(this._plan);

  final MealPlan? _plan;
  final List<GroceryItem> _groceryList = [
    GroceryItem(name: 'Oats', amount: '1 bag', category: 'Pantry'),
  ];
  final Set<String> _logged = {};

  @override
  MealPlan? get currentPlan => _plan;

  @override
  bool get isGenerating => false;

  @override
  bool get isRegenerating => false;

  @override
  String? get error => null;

  @override
  AsyncUiState get uiState =>
      _plan == null ? const AsyncUiState.empty() : const AsyncUiState.success();

  @override
  String? get fallbackNotice => null;

  @override
  String? get rebalanceNotice => null;

  @override
  bool get isCurrentPlanExpired => false;

  @override
  bool get canRegenerate => true;

  @override
  Set<String> get loggedPlannedMealIds => _logged;

  @override
  List<GroceryItem> get groceryList => _groceryList;

  @override
  void markPlannedMealLogged(String mealId) {
    _logged.add(mealId);
    notifyListeners();
  }

  @override
  void clearError() {}

  @override
  void clearFallbackNotice() {}

  @override
  void clearRebalanceNotice() {}

  @override
  Future<void> toggleGroceryItem(String id) async {
    final item = _groceryList.firstWhere((item) => item.id == id);
    item.isChecked = !item.isChecked;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  final bool _isPro;
  FakeSettingsProvider({bool isPro = false}) : _isPro = isPro;

  @override
  bool get isPro => _isPro;

  @override
  int get dailyCalorieGoal => 2000;

  @override
  String get languageCode => 'en';

  @override
  UserSettings get settings => UserSettings.defaults().copyWith(isPro: _isPro);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeConnectivityService extends ChangeNotifier
    implements ConnectivityService {
  @override
  bool get isOnline => true;

  @override
  bool get hasInternetAccess => true;

  @override
  Future<bool> refreshReachability({bool force = false}) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
