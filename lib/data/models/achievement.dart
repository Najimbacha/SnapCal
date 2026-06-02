import 'package:hive/hive.dart';

part 'achievement.g.dart';

enum AchievementCategory {
  consistency,
  precision,
  hydration,
  logging,
  progress,
}

/// An achievement that can be unlocked by the user
@HiveType(typeId: 12)
class Achievement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String titleKey;

  @HiveField(2)
  final String descriptionKey;

  @HiveField(3)
  final String emoji;

  @HiveField(4)
  final int categoryIndex;

  @HiveField(5)
  final int targetValue;

  @HiveField(6)
  bool isUnlocked;

  @HiveField(7)
  int? unlockedAt;

  @HiveField(8)
  int currentProgress;

  Achievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.emoji,
    required this.categoryIndex,
    required this.targetValue,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  AchievementCategory get category => AchievementCategory.values[categoryIndex];
  double get progressPercent =>
      targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;
}
