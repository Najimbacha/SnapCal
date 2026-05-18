import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/screens/home/widgets/macro_card.dart';

void main() {
  testWidgets('MacroCard renders without owning Expanded parent data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MacroCard(
            label: 'Protein',
            consumed: 42,
            goal: 120,
            color: Colors.green,
            icon: Icons.restaurant,
          ),
        ),
      ),
    );

    expect(find.text('Protein'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MacroCard can be expanded by a Row caller', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: MacroCard(
                  label: 'Carbs',
                  consumed: 84,
                  goal: 220,
                  color: Colors.orange,
                  icon: Icons.rice_bowl,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Carbs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
