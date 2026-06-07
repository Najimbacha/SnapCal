import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/log/widgets/horizontal_day_calendar.dart';

void main() {
  testWidgets('day cells do not overflow on compact calendar height', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final today = DateTime.now();
    final summaries = List.generate(14, (index) {
      final date = today.subtract(Duration(days: 13 - index));
      return DailySummary(
        dateString: _dateString(date),
        calories: index * 100,
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
        mealCount: index.isEven ? 1 : 0,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: HorizontalDayCalendar(
              selectedDate: summaries.last.dateString,
              dailySummaries: summaries,
              onDateSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

String _dateString(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
