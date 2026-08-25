import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/macro_display.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  // 42*4 + 84*4 + 20*9 = 684 kcal -> 25% / 49% / 26%
  final macros = Macros(protein: 42, carbs: 84, fat: 20);

  MacroDisplay build({
    MacroDisplayVariant variant = MacroDisplayVariant.detailed,
    bool showGrams = true,
    bool showGoals = true,
    VoidCallback? onUpgradeTap,
  }) =>
      MacroDisplay(
        macros: macros,
        proteinGoal: 120,
        carbGoal: 220,
        fatGoal: 70,
        variant: variant,
        showGrams: showGrams,
        showGoals: showGoals,
        onUpgradeTap: onUpgradeTap,
      );

  testWidgets('detailed variant renders without owning Expanded parent data', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(build()));

    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('can be expanded by a Row caller', (tester) async {
    await tester.pumpWidget(
      wrap(Row(children: [Expanded(child: build())])),
    );

    expect(find.text('Protein'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows grams against goals when goals are visible', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(build(variant: MacroDisplayVariant.compact)));

    expect(find.text('42'), findsOneWidget);
    expect(find.text(' / 120g'), findsOneWidget);
  });

  testWidgets('hides targets but keeps grams when goals are gated', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(build(variant: MacroDisplayVariant.compact, showGoals: false)),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text(' / 120g'), findsNothing);
    expect(find.text('g'), findsNWidgets(3));
  });

  testWidgets('composition variant shows real percentages, never a lock', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        build(
          variant: MacroDisplayVariant.composition,
          showGoals: false,
          onUpgradeTap: () {},
        ),
      ),
    );

    expect(find.text('25%'), findsOneWidget);
    expect(find.text('49%'), findsOneWidget);
    expect(find.text('26%'), findsOneWidget);

    // Grams stay visible alongside the composition for free users.
    expect(find.text('Protein 42g'), findsOneWidget);

    // One upgrade affordance, no padlocks and no placeholder dashes.
    expect(find.text('Daily targets and goal tracking'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsNothing);
    expect(find.textContaining('—g'), findsNothing);
  });

  testWidgets('composition withholds grams without blurring them', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        build(
          variant: MacroDisplayVariant.composition,
          showGrams: false,
          showGoals: false,
        ),
      ),
    );

    expect(find.text('25%'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Protein 42g'), findsNothing);
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('empty day states that nothing is logged', (tester) async {
    await tester.pumpWidget(
      wrap(
        MacroDisplay(
          macros: Macros.empty(),
          proteinGoal: 120,
          carbGoal: 220,
          fatGoal: 70,
          variant: MacroDisplayVariant.composition,
          showGoals: false,
        ),
      ),
    );

    expect(find.text('No meals logged yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('upgrade row fires its callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        build(
          variant: MacroDisplayVariant.composition,
          showGoals: false,
          onUpgradeTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Daily targets and goal tracking'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
