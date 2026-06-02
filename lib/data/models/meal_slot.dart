enum MealSlotStatus { done, next, upcoming }

class MealSlot {
  final String mealType; // "Breakfast", "Lunch", "Snack", "Dinner"
  final String name; // Suggested meal name
  final String time; // "8:00 AM", "Up next", "7:30 PM"
  final int kcal;
  final MealSlotStatus status;
  final bool isLogged;

  const MealSlot({
    required this.mealType,
    required this.name,
    required this.time,
    required this.kcal,
    required this.status,
    required this.isLogged,
  });

  MealSlot copyWith({
    String? mealType,
    String? name,
    String? time,
    int? kcal,
    MealSlotStatus? status,
    bool? isLogged,
  }) {
    return MealSlot(
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      time: time ?? this.time,
      kcal: kcal ?? this.kcal,
      status: status ?? this.status,
      isLogged: isLogged ?? this.isLogged,
    );
  }
}
