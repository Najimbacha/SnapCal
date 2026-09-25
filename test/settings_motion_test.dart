import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/settings/widgets/settings_kit.dart';
import 'package:snapcal/widgets/motion/rolling_number.dart';
import 'package:snapcal/widgets/motion/theme_reveal.dart';
import 'package:snapcal/widgets/motion/unfold.dart';
import 'package:snapcal/widgets/wazn_icons.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('value sheet', () {
    Future<List<int>> open(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final saved = <int>[];
      await tester.pumpWidget(
        _app(
          Builder(
            builder:
                (context) => Center(
                  child: TextButton(
                    onPressed:
                        () => showSettingsNumberDialog(
                          context,
                          title: 'Daily Calories',
                          currentValue: 2000,
                          unit: 'kcal',
                          min: 1200,
                          max: 4000,
                          step: 50,
                          onSave: (v) async => saved.add(v),
                        ),
                    child: const Text('open'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return saved;
    }

    testWidgets('a stepped number rolls to its new value', (tester) async {
      await open(tester);
      // The field underneath holds the same text as the number shown.
      expect(find.text('2000'), findsWidgets);

      await tester.tap(find.byIcon(WaznIcons.plus));
      // The roll starts on the frame after the tap.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      // Mid-roll the digits are drawn one by one.
      expect(find.bySemanticsLabel('2050'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('2050'), findsWidgets);
    });

    testWidgets('confirm draws a tick, then saves and closes', (tester) async {
      final saved = await open(tester);
      await tester.tap(find.byIcon(WaznIcons.plus));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 200));
      // Still open, showing the tick rather than the label.
      expect(find.byIcon(WaznIcons.check), findsOneWidget);
      expect(saved, isEmpty);

      await tester.pumpAndSettle();
      expect(saved, [2050]);
      expect(find.byIcon(WaznIcons.check), findsNothing);
    });

    testWidgets('tapping the number opens it for typing', (tester) async {
      await open(tester);
      await tester.tap(find.byType(RollingNumber));
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.focusNode!.hasFocus, isTrue);
    });
  });

  testWidgets('a row slides its new value in', (tester) async {
    Widget row(String value) => _app(
      SettingsRow(icon: WaznIcons.calories, title: 'Goal', value: value),
    );
    await tester.pumpWidget(row('2,000 kcal'));
    await tester.pumpWidget(row('2,100 kcal'));
    await tester.pump(const Duration(milliseconds: 120));
    // Old and new are both on their way.
    expect(find.text('2,000 kcal'), findsOneWidget);
    expect(find.text('2,100 kcal'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('2,000 kcal'), findsNothing);
    expect(find.text('2,100 kcal'), findsOneWidget);
  });

  testWidgets('Unfold opens and folds its child away', (tester) async {
    Widget fold(bool open) =>
        _app(Unfold(open: open, child: const Text('Breakfast 8:00')));
    await tester.pumpWidget(fold(false));
    expect(find.text('Breakfast 8:00'), findsNothing);

    await tester.pumpWidget(fold(true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Breakfast 8:00'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Breakfast 8:00'), findsOneWidget);

    await tester.pumpWidget(fold(false));
    await tester.pumpAndSettle();
    expect(find.text('Breakfast 8:00'), findsNothing);
  });

  group('theme reveal', () {
    testWidgets('without a host the change simply happens', (tester) async {
      var changed = false;
      await tester.pumpWidget(_app(const SizedBox()));
      await ThemeReveal.run(
        tester.element(find.byType(SizedBox)),
        origin: Offset.zero,
        change: () => changed = true,
      );
      expect(changed, isTrue);
    });

    testWidgets('with a host it changes under a picture, then clears', (
      tester,
    ) async {
      var changed = false;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ThemeRevealHost(child: child!),
          home: Scaffold(body: SizedBox(key: key)),
        ),
      );
      final reveal = ThemeReveal.run(
        key.currentContext!,
        origin: const Offset(100, 100),
        change: () => changed = true,
      );
      // Taking the picture is real work, outside the test clock.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      for (var i = 0; i < 5 && !changed; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(changed, isTrue);
      await tester.pumpAndSettle();
      await reveal;
      expect(tester.takeException(), isNull);
    });
  });
}
