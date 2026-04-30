// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MacrosAdapter extends TypeAdapter<Macros> {
  @override
  final int typeId = 0;

  @override
  Macros read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Macros(
      protein: fields[0] as int,
      carbs: fields[1] as int,
      fat: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Macros obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.protein)
      ..writeByte(1)
      ..write(obj.carbs)
      ..writeByte(2)
      ..write(obj.fat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacrosAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealAdapter extends TypeAdapter<Meal> {
  @override
  final int typeId = 1;

  @override
  Meal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meal(
      id: fields[0] as String,
      timestamp: fields[1] as int,
      dateString: fields[2] as String,
      imageUri: fields[3] as String?,
      foodName: fields[4] as String,
      calories: fields[5] as int,
      macros: fields[6] as Macros,
      synced: fields[7] as bool,
      ingredients: (fields[8] as List?)?.cast<String>(),
      prepTimeMins: fields[9] as int?,
      mealType: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Meal obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.dateString)
      ..writeByte(3)
      ..write(obj.imageUri)
      ..writeByte(4)
      ..write(obj.foodName)
      ..writeByte(5)
      ..write(obj.calories)
      ..writeByte(6)
      ..write(obj.macros)
      ..writeByte(7)
      ..write(obj.synced)
      ..writeByte(8)
      ..write(obj.ingredients)
      ..writeByte(9)
      ..write(obj.prepTimeMins)
      ..writeByte(10)
      ..write(obj.mealType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
