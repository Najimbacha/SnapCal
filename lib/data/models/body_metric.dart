import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'body_metric.g.dart';

@HiveType(typeId: 4) // Ensure this ID is unique
class BodyMetric extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double weight; // in kg

  @HiveField(3)
  final double? bodyFat; // percentage

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final String? photoFrontPath;

  @HiveField(6)
  final String? photoSidePath;

  BodyMetric({
    String? id,
    required this.date,
    required this.weight,
    this.bodyFat,
    this.note,
    this.photoFrontPath,
    this.photoSidePath,
  }) : id = id ?? const Uuid().v4();

  BodyMetric copyWith({
    DateTime? date,
    double? weight,
    double? bodyFat,
    String? note,
    String? photoFrontPath,
    String? photoSidePath,
  }) {
    return BodyMetric(
      id: id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      note: note ?? this.note,
      photoFrontPath: photoFrontPath ?? this.photoFrontPath,
      photoSidePath: photoSidePath ?? this.photoSidePath,
    );
  }
}
