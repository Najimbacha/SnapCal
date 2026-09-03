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

  testWidgets('rings variant shows grams and targets for Pro', (tester) async {
    await tester.pumpWidget(wrap(build(variant: MacroDisplayVariant.rings)));
    await tester.pumpAndSettle();

    // The ring renders grams as a Text.rich: the value and a smaller 'g'
    // span. find.text only reads Text.data unless it is told to flatten the
    // spans, which is why the old find.text('42') could never match.
    expect(find.text('42g', findRichText: true), findsOneWidget);
    // 120 - 42 = 78 left on protein.
    expect(find.text('78g to go'), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rings variant withholds the numbers when locked', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        build(
          variant: MacroDisplayVariant.rings,
          showGrams: false,
          showGoals: false,
          onUpgradeTap: () {},
        ),
      ),
    );
    await tester.pump();

    // One padlock for the section, on the CTA — not one per card as well.
    expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    expect(find.text('42g', findRichText: true), findsNothing);
    expect(find.text('78g to go'), findsNothing);
    // Grams are withheld, but the composition share is not: the same 25/49/26
    // the Log screen's bar shows, so the two screens cannot contradict.
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('49%'), findsOneWidget);
    expect(find.text('26%'), findsOneWidget);
    expect(find.text('See your exact numbers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked rings CTA speaks to the day and fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        build(
          variant: MacroDisplayVariant.rings,
          showGrams: false,
          showGoals: false,
          onUpgradeTap: () => tapped = true,
        ),
      ),
    );
    await tester.pump();

    // Fat sits at 20/70 = 29%, carbs at 84/220 = 38%, protein at 35% — none
    // clears the 60% "on track" bar, so the generic body shows.
    expect(find.text('Unlock grams and daily targets'), findsOneWidget);

    await tester.tap(find.text('See your exact numbers'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
