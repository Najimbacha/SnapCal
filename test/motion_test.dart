import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/home/widgets/home_nutrition_dashboard.dart';
import 'package:snapcal/screens/log/widgets/horizontal_day_calendar.dart';
import 'package:snapcal/widgets/motion/delta_bubble.dart';
import 'package:snapcal/widgets/motion/count_up_text.dart';
import 'package:snapcal/widgets/motion/reveal.dart';
import 'package:snapcal/widgets/motion/rolling_number.dart';
import 'package:snapcal/widgets/motion/tab_switcher.dart';
import 'package:snapcal/widgets/motion/water_glass.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder:
      (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: app!,
      ),
  home: Scaffold(body: Center(child: child)),
);

const _style = TextStyle(fontSize: 40);

void main() {
  group('RollingNumber', () {
    testWidgets('rolls between values and rests as plain text', (tester) async {
      await tester.pumpWidget(
        _app(const RollingNumber(value: 1284, style: _style)),
      );
      expect(find.text('1,284'), findsOneWidget);

      await tester.pumpWidget(
        _app(const RollingNumber(value: 761, style: _style)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Mid-roll the digits are drawn one by one, labelled with the target.
      expect(find.text('761'), findsNothing);
      expect(find.bySemanticsLabel('761'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('761'), findsOneWidget);
    });

    testWidgets('rolls in from a starting value on first show', (tester) async {
      await tester.pumpWidget(
        _app(const RollingNumber(value: 1284, from: 2000, style: _style)),
      );
      expect(find.text('1,284'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('1,284'), findsOneWidget);
    });

    testWidgets('waits while off screen, then rolls when shown', (
      tester,
    ) async {
      Widget at(int value, {required bool visible}) => _app(
        TickerMode(
          enabled: visible,
          child: RollingNumber(value: value, style: _style),
        ),
      );
      await tester.pumpWidget(at(1284, visible: true));
      await tester.pumpWidget(at(761, visible: false));
      await tester.pump(const Duration(seconds: 2));
      // Still the old figure: the change has not been seen yet.
      expect(find.text('1,284'), findsOneWidget);

      await tester.pumpWidget(at(761, visible: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.bySemanticsLabel('761'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('761'), findsOneWidget);
    });

    testWidgets('jumps straight to the value with reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const RollingNumber(value: 1284, from: 2000, style: _style),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('1,284'), findsOneWidget);
    });

    testWidgets('rolls Arabic-Indic digits', (tester) async {
      String arabic(int v) =>
          v
              .toString()
              .split('')
              .map((d) => String.fromCharCode(0x660 + int.parse(d)))
              .join();
      await tester.pumpWidget(
        _app(RollingNumber(value: 12, format: arabic, style: _style)),
      );
      await tester.pumpWidget(
        _app(RollingNumber(value: 345, format: arabic, style: _style)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('٣٤٥'), findsOneWidget);
    });
  });

  testWidgets('CountUpText counts from its start value', (tester) async {
    await tester.pumpWidget(_app(const CountUpText(value: 716, from: 0)));
    expect(find.text('0'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('716'), findsOneWidget);
  });

  testWidgets('Reveal ends fully shown and in place', (tester) async {
    await tester.pumpWidget(
      _app(
        const Reveal(
          delay: Duration(milliseconds: 200),
          child: Text('Grilled chicken'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Grilled chicken'),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 1);
  });

  testWidgets('WaterGlass settles after a change and is still at rest', (
    tester,
  ) async {
    Widget glass(double level) => _app(
      WaterGlass(
        level: level,
        color: Colors.blue,
        outline: Colors.grey,
        showDrop: true,
      ),
    );
    await tester.pumpWidget(glass(.4));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('40%'), findsOneWidget);
    await tester.pumpWidget(glass(.5));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('50%'), findsOneWidget);
  });

  group('TabSwitcher', () {
    testWidgets('keeps every page alive and shows only the current one', (
      tester,
    ) async {
      Widget tabs(int index) => _app(
        SizedBox(
          width: 300,
          height: 300,
          child: TabSwitcher(
            currentIndex: index,
            children: const [_Counter('a'), _Counter('b'), _Counter('c')],
          ),
        ),
      );
      await tester.pumpWidget(tabs(0));
      await tester.tap(find.text('a 0'));
      await tester.pump();
      expect(find.text('a 1'), findsOneWidget);

      await tester.pumpWidget(tabs(1));
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-switch both pages are on screen.
      expect(find.text('a 1'), findsOneWidget);
      expect(find.text('b 0'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('a 1'), findsNothing);
      expect(find.text('a 1', skipOffstage: false), findsOneWidget);

      await tester.pumpWidget(tabs(0));
      await tester.pumpAndSettle();
      // Its state survived the trip.
      expect(find.text('a 1'), findsOneWidget);
    });
  });

  group('protein goal', () {
    Widget section(int protein, {bool hasMeals = true}) => _app(
      SingleChildScrollView(
        child: HomeMacroSection(
          macros: Macros(protein: protein, carbs: 100, fat: 30),
          proteinGoal: 140,
          carbGoal: 260,
          fatGoal: 70,
          isPro: true,
          hasMeals: hasMeals,
          onUpgrade: () {},
        ),
      ),
    );

    testWidgets('is celebrated when a meal crosses it', (tester) async {
      await tester.pumpWidget(section(120));
      await tester.pumpAndSettle();
      expect(find.text('Protein goal reached today'), findsNothing);

      await tester.pumpWidget(section(150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Protein goal reached today'), findsOneWidget);
      expect(find.text('150 g of protein today'), findsOneWidget);

      // The note and the confetti clear themselves away.
      await tester.pumpAndSettle();
      expect(find.text('Protein goal reached today'), findsNothing);
    });

    testWidgets('is not celebrated when the day loads already met', (
      tester,
    ) async {
      await tester.pumpWidget(section(0, hasMeals: false));
      await tester.pumpWidget(section(150));
      await tester.pumpAndSettle();
      expect(find.text('Protein goal reached today'), findsNothing);
    });
  });

  testWidgets('the day highlight slides to the day picked', (tester) async {
    final today = DateTime.now();
    String day(int back) {
      final d = DateTime(today.year, today.month, today.day - back);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    final summaries = [
      for (var i = 6; i >= 0; i--)
        DailySummary(
          dateString: day(i),
          calories: 1800,
          calorieGoal: 2000,
          protein: 0,
          proteinGoal: 120,
          carbs: 0,
          carbGoal: 220,
          fat: 0,
          fatGoal: 70,
          waterMl: 0,
          waterGoal: 2000,
          steps: 0,
          stepGoal: 8000,
          mealCount: 1,
        ),
    ];
    Widget strip(String selected) => _app(
      SizedBox(
        width: 360,
        child: HorizontalDayCalendar(
          selectedDate: selected,
          dailySummaries: summaries,
          onDateSelected: (_) {},
        ),
      ),
    );
    double highlightX() =>
        tester.getTopLeft(find.byKey(const ValueKey('day-highlight'))).dx;

    await tester.pumpWidget(strip(day(0)));
    await tester.pumpAndSettle();
    final start = highlightX();

    await tester.pumpWidget(strip(day(3)));
    await tester.pump(const Duration(milliseconds: 150));
    final midway = highlightX();
    await tester.pumpAndSettle();
    final end = highlightX();
    expect(end, closeTo(start - 3 * 50, 1));
    // It travelled there rather than jumping.
    expect(midway, lessThan(start));
    expect(midway, greaterThan(end));
  });

  testWidgets('DeltaBubble floats a signed change and clears', (tester) async {
    await tester.pumpWidget(_app(const DeltaBubble(value: 1220)));
    await tester.pumpWidget(_app(const DeltaBubble(value: 610)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('\u2212610'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('\u2212610'), findsNothing);

    // A change that is not an add or removal passes quietly.
    await tester.pumpWidget(
      _app(const DeltaBubble(value: 1980, announce: false)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('1,370'), findsNothing);
  });
}

class _Counter extends StatefulWidget {
  const _Counter(this.name);

  final String name;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _taps++),
    child: Text('${widget.name} $_taps'),
  );
}
