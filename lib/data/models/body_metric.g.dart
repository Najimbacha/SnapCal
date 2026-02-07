// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_metric.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyMetricAdapter extends TypeAdapter<BodyMetric> {
  @override
  final int typeId = 4;

  @override
  BodyMetric read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyMetric(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      weight: fields[2] as double,
      bodyFat: fields[3] as double?,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BodyMetric obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.bodyFat)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMetricAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
