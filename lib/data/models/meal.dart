import 'package:hive/hive.dart';

part 'meal.g.dart';

/// Macronutrient data
@HiveType(typeId: 0)
class Macros extends HiveObject {
  @HiveField(0)
  final int protein;

  @HiveField(1)
  final int carbs;

  @HiveField(2)
  final int fat;

  Macros({required this.protein, required this.carbs, required this.fat});

  Macros copyWith({int? protein, int? carbs, int? fat}) {
    return Macros(
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  Map<String, dynamic> toJson() {
    return {'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  factory Macros.fromJson(Map<String, dynamic> json) {
    return Macros(
      protein: json['protein'] as int? ?? 0,
      carbs: json['carbs'] as int? ?? 0,
      fat: json['fat'] as int? ?? 0,
    );
  }

  static Macros empty() => Macros(protein: 0, carbs: 0, fat: 0);
}

/// Meal data model
@HiveType(typeId: 1)
class Meal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int timestamp;

  @HiveField(2)
  final String dateString;

  @HiveField(3)
  final String? imageUri;

  @HiveField(4)
  final String foodName;

  @HiveField(5)
  final int calories;

  @HiveField(6)
  final Macros macros;

  @HiveField(7)
  final bool synced;

  // Planner-specific fields (nullable for backward compat)
  @HiveField(8)
  final List<String>? ingredients;

  @HiveField(9)
  final int? prepTimeMins;

  @HiveField(10)
  final String? mealType; // "Breakfast", "Lunch", "Dinner", "Snack"

  @HiveField(11)
  final String? portion;

  @HiveField(12)
  final double? scanConfidence;

  @HiveField(13)
  final String? scanSource;

  @HiveField(14)
  final String? aiRationale;

  @HiveField(15)
  final int? originalCalories;

  @HiveField(16)
  final bool userCorrected;

  @HiveField(17)
  final double? weightG;

  @HiveField(18)
  final String? nutritionMatchId;

  @HiveField(19)
  final Map<String, dynamic>? nutritionPer100g;

  Meal({
    required this.id,
    required this.timestamp,
    required this.dateString,
    this.imageUri,
    required this.foodName,
    required this.calories,
    required this.macros,
    this.synced = false,
    this.ingredients,
    this.prepTimeMins,
    this.mealType,
    this.portion,
    this.scanConfidence,
    this.scanSource,
    this.aiRationale,
    this.originalCalories,
    this.userCorrected = false,
    this.weightG,
    this.nutritionMatchId,
    this.nutritionPer100g,
  });

  Meal copyWith({
    String? id,
    int? timestamp,
    String? dateString,
    String? imageUri,
    String? foodName,
    int? calories,
    Macros? macros,
    bool? synced,
    List<String>? ingredients,
    int? prepTimeMins,
    String? mealType,
    String? portion,
    double? scanConfidence,
    String? scanSource,
    String? aiRationale,
    int? originalCalories,
    bool? userCorrected,
    double? weightG,
    String? nutritionMatchId,
    Map<String, dynamic>? nutritionPer100g,
  }) {
    return Meal(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      dateString: dateString ?? this.dateString,
      imageUri: imageUri ?? this.imageUri,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      macros: macros ?? this.macros,
      synced: synced ?? this.synced,
      ingredients: ingredients ?? this.ingredients,
      prepTimeMins: prepTimeMins ?? this.prepTimeMins,
      mealType: mealType ?? this.mealType,
      portion: portion ?? this.portion,
      scanConfidence: scanConfidence ?? this.scanConfidence,
      scanSource: scanSource ?? this.scanSource,
      aiRationale: aiRationale ?? this.aiRationale,
      originalCalories: originalCalories ?? this.originalCalories,
      userCorrected: userCorrected ?? this.userCorrected,
      weightG: weightG ?? this.weightG,
      nutritionMatchId: nutritionMatchId ?? this.nutritionMatchId,
      nutritionPer100g: nutritionPer100g ?? this.nutritionPer100g,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'dateString': dateString,
      'imageUri': imageUri,
      'foodName': foodName,
      'calories': calories,
      'macros': macros.toJson(),
      'synced': synced,
      'ingredients': ingredients,
      'prepTimeMins': prepTimeMins,
      'mealType': mealType,
      'portion': portion,
      'scanConfidence': scanConfidence,
      'scanSource': scanSource,
      'aiRationale': aiRationale,
      'originalCalories': originalCalories,
      'userCorrected': userCorrected,
      'weightG': weightG,
      'nutritionMatchId': nutritionMatchId,
      'nutritionPer100g': nutritionPer100g,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      timestamp: json['timestamp'] as int,
      dateString: json['dateString'] as String,
      imageUri: json['imageUri'] as String?,
      foodName: json['foodName'] as String,
      calories: json['calories'] as int,
      macros: Macros.fromJson(json['macros'] as Map<String, dynamic>),
      synced: json['synced'] as bool? ?? false,
      ingredients: (json['ingredients'] as List?)?.cast<String>(),
      prepTimeMins: json['prepTimeMins'] as int?,
      mealType: json['mealType'] as String?,
      portion: json['portion'] as String?,
      scanConfidence: (json['scanConfidence'] as num?)?.toDouble(),
      scanSource: json['scanSource'] as String?,
      aiRationale: json['aiRationale'] as String?,
      originalCalories: json['originalCalories'] as int?,
      userCorrected: json['userCorrected'] as bool? ?? false,
      weightG: (json['weightG'] as num?)?.toDouble(),
      nutritionMatchId: json['nutritionMatchId'] as String?,
      nutritionPer100g: json['nutritionPer100g'] as Map<String, dynamic>?,
    );
  }

  /// Get formatted time (HH:MM)
  String get formattedTime {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date (MMM d)
  String get formattedDate {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}
