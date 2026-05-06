// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TemplateItemAdapter extends TypeAdapter<TemplateItem> {
  @override
  final int typeId = 10;

  @override
  TemplateItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemplateItem(
      foodName: fields[0] as String,
      calories: fields[1] as int,
      protein: fields[2] as int,
      carbs: fields[3] as int,
      fat: fields[4] as int,
      servingSize: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TemplateItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.foodName)
      ..writeByte(1)
      ..write(obj.calories)
      ..writeByte(2)
      ..write(obj.protein)
      ..writeByte(3)
      ..write(obj.carbs)
      ..writeByte(4)
      ..write(obj.fat)
      ..writeByte(5)
      ..write(obj.servingSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealTemplateAdapter extends TypeAdapter<MealTemplate> {
  @override
  final int typeId = 11;

  @override
  MealTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      items: (fields[3] as List).cast<TemplateItem>(),
      createdAt: fields[4] as int,
      usageCount: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MealTemplate obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.usageCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
