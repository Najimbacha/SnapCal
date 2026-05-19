class ActivitySummary {
  final DateTime date;
  final int steps;
  final int stepGoal;
  final int activityCalories;
  final int manualWorkoutCalories;
  final int stepStreak;
  final int activityScore;
  final List<WorkoutEntry> workouts;

  const ActivitySummary({
    required this.date,
    this.steps = 0,
    this.stepGoal = 10000,
    this.activityCalories = 0,
    this.manualWorkoutCalories = 0,
    this.stepStreak = 0,
    this.activityScore = 0,
    this.workouts = const [],
  });

  factory ActivitySummary.empty(DateTime date) {
    return ActivitySummary(date: DateTime(date.year, date.month, date.day));
  }

  ActivitySummary copyWith({
    DateTime? date,
    int? steps,
    int? stepGoal,
    int? activityCalories,
    int? manualWorkoutCalories,
    int? stepStreak,
    int? activityScore,
    List<WorkoutEntry>? workouts,
  }) {
    return ActivitySummary(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      stepGoal: stepGoal ?? this.stepGoal,
      activityCalories: activityCalories ?? this.activityCalories,
      manualWorkoutCalories:
          manualWorkoutCalories ?? this.manualWorkoutCalories,
      stepStreak: stepStreak ?? this.stepStreak,
      activityScore: activityScore ?? this.activityScore,
      workouts: workouts ?? this.workouts,
    );
  }
}

class WorkoutEntry {
  final String id;
  final String type;
  final DateTime start;
  final DateTime end;
  final int calories;

  const WorkoutEntry({
    required this.id,
    required this.type,
    required this.start,
    required this.end,
    this.calories = 0,
  });

  Duration get duration => end.difference(start);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'calories': calories,
    };
  }

  factory WorkoutEntry.fromJson(Map<dynamic, dynamic> json) {
    return WorkoutEntry(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Workout',
      start: DateTime.fromMillisecondsSinceEpoch(json['start'] as int? ?? 0),
      end: DateTime.fromMillisecondsSinceEpoch(json['end'] as int? ?? 0),
      calories: json['calories'] as int? ?? 0,
    );
  }
}
