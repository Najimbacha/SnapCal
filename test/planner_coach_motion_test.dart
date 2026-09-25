import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/models/grocery_item.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/repositories/assistant_repository.dart';
import 'package:snapcal/data/services/premium_gate_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/assistant_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/assistant/assistant_screen.dart';
import 'package:snapcal/screens/planner/meal_planner_widgets.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Meal _meal() => Meal(
  id: 'lunch',
  timestamp: DateTime(2026, 9, 8, 13).millisecondsSinceEpoch,
  dateString: '2026-09-08',
  foodName: 'Grilled chicken rice bowl',
  calories: 610,
  macros: Macros(protein: 46, carbs: 64, fat: 18),
  mealType: 'Lunch',
  prepTimeMins: 25,
);

class _EmptyChat implements AssistantRepository {
  @override
  List<Map<String, String>> getCoachChat() => const [];
  @override
  Future<void> saveCoachChat(List<Map<String, String>> messages) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers when the test says so, and not before.
class _SlowAssistant extends Assistant {
  _SlowAssistant(this.reply);
  final Completer<String> reply;

  @override
  Future<String> fetchRecommendations(
    String query, {
    int? currentCalories,
    List<Map<String, String>> history = const [],
  }) => reply.future;
}

void main() {
  group('Meal Planner', () {
    testWidgets('the tab card slides across to the list picked', (
      tester,
    ) async {
      Widget tabs(bool grocery) => _host(
        SizedBox(
          width: 360,
          child: PlannerTabs(
            grocerySelected: grocery,
            onPlan: () {},
            onGrocery: () {},
          ),
        ),
      );
      double thumbX() =>
          tester.getTopLeft(find.byKey(const ValueKey('planner-tab-thumb'))).dx;

      await tester.pumpWidget(tabs(false));
      final start = thumbX();
      await tester.pumpWidget(tabs(true));
      await tester.pump(const Duration(milliseconds: 100));
      final midway = thumbX();
      await tester.pumpAndSettle();
      final end = thumbX();
      expect(end, greaterThan(start + 100));
      expect(midway, greaterThan(start));
      expect(midway, lessThan(end));
    });

    testWidgets('a logged meal gets a tick on its photo', (tester) async {
      Widget row(bool logged) => _host(
        PlannerMealRow(
          meal: _meal(),
          isNext: false,
          isLogged: logged,
          interactive: true,
          onOpen: () {},
          onLog: () {},
          onSwap: () {},
        ),
      );
      double badge() =>
          tester
              .widget<AnimatedScale>(
                find.byKey(const ValueKey('planner-logged-badge')),
              )
              .scale;

      await tester.pumpWidget(row(false));
      expect(badge(), 0);
      await tester.pumpWidget(row(true));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpAndSettle();
      expect(badge(), 1);
      expect(find.byTooltip('Logged'), findsOneWidget);
    });

    testWidgets('the day totals count to a swapped meal', (tester) async {
      Widget band(int calories) => _host(
        PlannerNutritionBand(
          meals: [_meal().copyWith(calories: calories)],
          calorieGoal: 2000,
          proteinGoal: 140,
          carbGoal: 220,
          fatGoal: 70,
        ),
      );
      await tester.pumpWidget(band(610));
      expect(find.text('610'), findsOneWidget);

      await tester.pumpWidget(band(750));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('610'), findsNothing);
      expect(find.text('750'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('750'), findsOneWidget);
    });

    testWidgets('ticking a grocery item draws it off the list', (tester) async {
      final tomatoes = GroceryItem(
        name: 'Tomatoes',
        amount: '6',
        category: 'Produce',
      );
      final chicken = GroceryItem(
        name: 'Chicken breast',
        amount: '1 kg',
        category: 'Protein',
        isChecked: true,
      );
      final toggled = <String>[];
      Widget view(bool tomatoesChecked) {
        final items = [tomatoes.copyWith(isChecked: tomatoesChecked), chicken];
        return _host(
          GroceryPlannerView(
            items: items,
            groupedItems: {
              'Produce': [items[0]],
              'Protein': [items[1]],
            },
            selectedFilter: 0,
            shoppingMode: false,
            onFilterChanged: (_) {},
            onToggle: (id) async => toggled.add(id),
            onClearChecked: () async {},
            onShoppingMode: () {},
            onShare: () {},
          ),
        );
      }

      await tester.pumpWidget(view(false));
      expect(find.text('1 of 2'), findsOneWidget);
      await tester.tap(find.text('Tomatoes'));
      expect(toggled, [tomatoes.id]);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(view(true));
      await tester.pump(const Duration(milliseconds: 150));
      // Mid-tick the name is already on its way to muted.
      final midColor = tester.widget<Text>(find.text('Tomatoes')).style!.color!;
      await tester.pumpAndSettle();
      final endColor = tester.widget<Text>(find.text('Tomatoes')).style!.color!;
      expect(midColor, isNot(endColor));
      expect(find.text('2 of 2'), findsOneWidget);
      expect(
        tester.getSemantics(
          find
              .ancestor(
                of: find.text('Tomatoes'),
                matching: find.byType(InkWell),
              )
              .first,
        ),
        matchesSemantics(
          isChecked: true,
          hasCheckedState: true,
          isButton: false,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Tomatoes\n6',
        ),
      );
      handle.dispose();
    });

    testWidgets('the building ring creeps forward rather than jumping', (
      tester,
    ) async {
      await tester.pumpWidget(_host(PlannerGeneratingScreen(onLeave: () {})));
      double ring() =>
          tester
              .widget<CircularProgressIndicator>(
                find.descendant(
                  of: find.byKey(const ValueKey('planner-generating-ring')),
                  matching: find.byType(CircularProgressIndicator),
                ),
              )
              .value!;
      await tester.pump(const Duration(milliseconds: 500));
      final early = ring();
      expect(early, greaterThan(0));
      expect(early, lessThan(.25));
      await tester.pump(const Duration(seconds: 3));
      expect(ring(), greaterThan(early));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('AI Coach', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final gate = PremiumGateService()..resetForTesting();
      await gate.init();
    });

    testWidgets('says it is thinking, then waves the answer in', (
      tester,
    ) async {
      final reply = Completer<String>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            proAccessProvider.overrideWith((ref) => ProAccess(ProStatus.pro)),
            assistantRepositoryProvider.overrideWith(
              (ref) async => _EmptyChat(),
            ),
            assistantProvider.overrideWith(() => _SlowAssistant(reply)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AssistantScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.enterText(find.byType(TextField), 'How much protein?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('How much protein?', findRichText: true), findsOne);
      expect(find.text('Thinking…'), findsOneWidget);

      reply.complete('Aim for **140 g** a day, spread over your meals.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      const plain = 'Aim for 140 g a day, spread over your meals.';
      final wave = tester.widget<RichText>(
        find.text(plain, findRichText: true),
      );
      final words = (wave.text as TextSpan).children!.cast<TextSpan>();
      // The first words are in while the last are still arriving, and the
      // bold stays bold throughout.
      expect(
        words.first.style!.color!.a,
        greaterThan(words.last.style!.color!.a),
      );
      expect(
        words.firstWhere((w) => w.text!.contains('140')).style!.fontWeight,
        FontWeight.w700,
      );

      await tester.pumpAndSettle();
      expect(find.text(plain, findRichText: true), findsOneWidget);
      expect(find.text('Thinking…'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
