import 'package:hive/hive.dart';
import 'meal.dart';

part 'meal_plan.g.dart';

@HiveType(typeId: 6)
class MealPlan extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startDate;

  @HiveField(2)
  final DateTime endDate;

  // Map of day index (0=Monday, 6=Sunday) to list of meals
  @HiveField(3)
  final Map<int, List<Meal>> weeklyMeals;

  MealPlan({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.weeklyMeals,
  });

  /// Factory to create a new empty plan starting from next Monday or a given date
  factory MealPlan.createEmpty({DateTime? start}) {
    // Logic to find start of week could go here, for now just simple init
    final s = start ?? DateTime.now();
    final e = s.add(const Duration(days: 6));

    return MealPlan(
      id: 'current_plan', // For now, single plan pattern? Or UUID
      startDate: s,
      endDate: e,
      weeklyMeals: {0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: []},
    );
  }

  MealPlan copyWith({Map<int, List<Meal>>? weeklyMeals}) {
    return MealPlan(
      id: id,
      startDate: startDate,
      endDate: endDate,
      weeklyMeals: weeklyMeals ?? this.weeklyMeals,
    );
  }
}
