import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/providers/settings_provider.dart';

Meal _meal(String? type, {String date = '2026-09-11'}) => Meal(
  id: 'm-$type',
  timestamp: 0,
  dateString: date,
  foodName: 'Food',
  calories: 300,
  macros: Macros.empty(),
  mealType: type,
);

void main() {
  // Defaults: breakfast 08:00, lunch 13:00, dinner 19:00.
  final settings = UserSettings.defaults();

  int? skip(Meal meal, DateTime now, [UserSettings? s]) =>
      Settings.mealReminderToSkip(
        meal: meal,
        settings: s ?? settings,
        now: now,
      );

  test('logging a meal before its reminder skips that reminder', () {
    expect(skip(_meal('Breakfast'), DateTime(2026, 9, 11, 7, 30)), 1);
    expect(skip(_meal('Lunch'), DateTime(2026, 9, 11, 12, 15)), 2);
    expect(skip(_meal('Dinner'), DateTime(2026, 9, 11, 18, 59)), 3);
  });

  test('nothing to skip once the reminder has gone off', () {
    expect(skip(_meal('Breakfast'), DateTime(2026, 9, 11, 8, 0)), isNull);
    expect(skip(_meal('Lunch'), DateTime(2026, 9, 11, 14, 0)), isNull);
  });

  test('snacks, other days and reminders turned off skip nothing', () {
    final now = DateTime(2026, 9, 11, 7, 0);
    expect(skip(_meal('Snack'), now), isNull);
    expect(skip(_meal(null), now), isNull);
    expect(skip(_meal('Breakfast', date: '2026-09-10'), now), isNull);
    expect(
      skip(
        _meal('Breakfast'),
        now,
        settings.copyWith(mealRemindersEnabled: false),
      ),
      isNull,
    );
    expect(
      skip(
        _meal('Breakfast'),
        now,
        settings.copyWith(notificationsEnabled: false),
      ),
      isNull,
    );
  });
}
