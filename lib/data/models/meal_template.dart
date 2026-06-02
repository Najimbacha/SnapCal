import 'package:hive/hive.dart';

part 'meal_template.g.dart';

/// A single food item within a template
@HiveType(typeId: 10)
class TemplateItem extends HiveObject {
  @HiveField(0)
  final String foodName;

  @HiveField(1)
  final int calories;

  @HiveField(2)
  final int protein;

  @HiveField(3)
  final int carbs;

  @HiveField(4)
  final int fat;

  @HiveField(5)
  final String? servingSize;

  TemplateItem({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingSize,
  });

  Map<String, dynamic> toJson() => {
    'foodName': foodName,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'servingSize': servingSize,
  };

  factory TemplateItem.fromJson(Map<String, dynamic> json) => TemplateItem(
    foodName: json['foodName'] as String,
    calories: json['calories'] as int? ?? 0,
    protein: json['protein'] as int? ?? 0,
    carbs: json['carbs'] as int? ?? 0,
    fat: json['fat'] as int? ?? 0,
    servingSize: json['servingSize'] as String?,
  );
}

/// A reusable meal template ("My Routines")
@HiveType(typeId: 11)
class MealTemplate extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String emoji;

  @HiveField(3)
  final List<TemplateItem> items;

  @HiveField(4)
  final int createdAt;

  @HiveField(5)
  int usageCount;

  MealTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.items,
    required this.createdAt,
    this.usageCount = 0,
  });

  int get totalCalories => items.fold(0, (sum, i) => sum + i.calories);
  int get totalProtein => items.fold(0, (sum, i) => sum + i.protein);
  int get totalCarbs => items.fold(0, (sum, i) => sum + i.carbs);
  int get totalFat => items.fold(0, (sum, i) => sum + i.fat);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'items': items.map((i) => i.toJson()).toList(),
    'createdAt': createdAt,
    'usageCount': usageCount,
  };

  factory MealTemplate.fromJson(Map<String, dynamic> json) => MealTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String? ?? '🍽️',
    items:
        (json['items'] as List).map((i) => TemplateItem.fromJson(i)).toList(),
    createdAt: json['createdAt'] as int,
    usageCount: json['usageCount'] as int? ?? 0,
  );
}
