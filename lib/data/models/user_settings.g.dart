// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 2;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      dailyCalorieGoal: fields[0] as int,
      dailyProteinGoal: fields[1] as int,
      dailyCarbGoal: fields[2] as int,
      dailyFatGoal: fields[3] as int,
      isPro: fields[4] as bool,
      currentStreak: fields[5] as int,
      lastLoggedDate: fields[6] as String?,
      notificationsEnabled: fields[7] as bool,
      mealRemindersEnabled: fields[8] as bool,
      goalAlertsEnabled: fields[9] as bool,
      breakfastTime: fields[10] as String,
      lunchTime: fields[11] as String,
      dinnerTime: fields[12] as String,
      height: fields[13] as double?,
      targetWeight: fields[14] as double?,
      themeMode: (fields[15] as String?) ?? 'system',
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.dailyCalorieGoal)
      ..writeByte(1)
      ..write(obj.dailyProteinGoal)
      ..writeByte(2)
      ..write(obj.dailyCarbGoal)
      ..writeByte(3)
      ..write(obj.dailyFatGoal)
      ..writeByte(4)
      ..write(obj.isPro)
      ..writeByte(5)
      ..write(obj.currentStreak)
      ..writeByte(6)
      ..write(obj.lastLoggedDate)
      ..writeByte(7)
      ..write(obj.notificationsEnabled)
      ..writeByte(8)
      ..write(obj.mealRemindersEnabled)
      ..writeByte(9)
      ..write(obj.goalAlertsEnabled)
      ..writeByte(10)
      ..write(obj.breakfastTime)
      ..writeByte(11)
      ..write(obj.lunchTime)
      ..writeByte(12)
      ..write(obj.dinnerTime)
      ..writeByte(13)
      ..write(obj.height)
      ..writeByte(14)
      ..write(obj.targetWeight)
      ..writeByte(15)
      ..write(obj.themeMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
