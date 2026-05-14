import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/screens/home/widgets/recent_meal_tile.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('RecentMealTile renders cached meal with zero macros', (
    tester,
  ) async {
    final meal = Meal(
      id: 'meal-1',
      timestamp: DateTime(2026, 5, 11, 9, 30).millisecondsSinceEpoch,
      dateString: '2026-05-11',
      foodName: 'Manual fallback meal',
      calories: 320,
      macros: Macros(protein: 0, carbs: 0, fat: 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RecentMealTile(meal: meal, onTap: () {})),
      ),
    );

    expect(find.text('Manual fallback meal'), findsOneWidget);
    expect(find.text('320'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
