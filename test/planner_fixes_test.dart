import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/providers/planner_provider.dart';

void main() {
  test('the refresh limit counts the last seven days, not the session', () {
    final now = DateTime(2026, 9, 12, 12);
    final log = [
      now.subtract(const Duration(days: 8)).millisecondsSinceEpoch,
      now.subtract(const Duration(days: 6)).millisecondsSinceEpoch,
      now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
    ];
    expect(PlannerProvider.regensWithin(log, now), hasLength(2));
    expect(PlannerProvider.regensWithin(const [], now), isEmpty);
  });

  test('a planned meal is logged under one id per day', () {
    expect(
      PlannerProvider.logIdFor('abc', '2026-09-12'),
      'planned_abc_2026-09-12',
    );
    expect(
      PlannerProvider.logIdFor('abc', '2026-09-12'),
      isNot(PlannerProvider.logIdFor('abc', '2026-09-13')),
    );
  });

  test('an ingredient another meal still uses stays on the list', () {
    const plan = {'olive oil', 'rice', 'chicken breast'};
    expect(PlannerProvider.groceryStillNeeded('Olive oil', plan), isTrue);
    expect(PlannerProvider.groceryStillNeeded('Chicken', plan), isTrue);
    expect(PlannerProvider.groceryStillNeeded('Salmon', plan), isFalse);
  });
}
