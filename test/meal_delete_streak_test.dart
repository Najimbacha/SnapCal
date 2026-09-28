import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';

/// Meals kept in memory.
class _Meals extends Fake implements MealRepository {
  _Meals(List<Meal> meals) : _meals = {for (final m in meals) m.id: m};

  final Map<String, Meal> _meals;

  @override
  Meal? getMeal(String id) => _meals[id];

  @override
  List<Meal> getMealsByDate(String dateString) =>
      _meals.values.where((m) => m.dateString == dateString).toList();

  @override
  Future<void> deleteMeal(String id) async => _meals.remove(id);
}

/// Records the streak recounts it is asked for.
class _Settings extends Settings {
  final recounts = <String>[];

  @override
  Future<UserSettings> build() async => UserSettings.defaults();

  @override
  Future<void> adjustStreakOnDeletion({
    required String dateOfDeletedMeal,
    required bool wasLastMealOfDay,
  }) async {
    if (wasLastMealOfDay) recounts.add(dateOfDeletedMeal);
  }
}

Meal _meal(String id, String date) => Meal(
  id: id,
  timestamp: DateTime.parse(date).millisecondsSinceEpoch,
  dateString: date,
  foodName: 'Toast',
  calories: 120,
  macros: Macros(protein: 4, carbs: 20, fat: 2),
);

void main() {
  late _Settings settings;
  late ProviderContainer container;

  setUp(() {
    settings = _Settings();
    container = ProviderContainer(
      overrides: [
        mealRepositoryProvider.overrideWith(
          (ref) async => _Meals([
            _meal('a', '2026-09-28'),
            _meal('b', '2026-09-28'),
            _meal('c', '2026-09-27'),
          ]),
        ),
        settingsProvider.overrideWith(() => settings),
      ],
    );
    addTearDown(container.dispose);
  });

  test('the last meal of a day gone, the streak is counted again', () async {
    final log = container.read(mealLogProvider.notifier);
    await log.deleteMeal('c');
    await Future<void>.delayed(Duration.zero);
    expect(settings.recounts, ['2026-09-27']);
  });

  test('a day with meals left keeps its streak as it is', () async {
    final log = container.read(mealLogProvider.notifier);
    await log.deleteMeal('a');
    await Future<void>.delayed(Duration.zero);
    expect(settings.recounts, isEmpty);

    await log.deleteMeal('b');
    await Future<void>.delayed(Duration.zero);
    expect(settings.recounts, ['2026-09-28']);
  });
}
