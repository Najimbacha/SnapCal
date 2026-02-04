import 'package:hive/hive.dart';

part 'water_log.g.dart';

@HiveType(typeId: 3)
class WaterLog extends HiveObject {
  @HiveField(0)
  final String dateString;

  @HiveField(1)
  final int amountMl;

  @HiveField(2)
  final int timestamp;

  WaterLog({
    required this.dateString,
    required this.amountMl,
    required this.timestamp,
  });

  WaterLog copyWith({String? dateString, int? amountMl, int? timestamp}) {
    return WaterLog(
      dateString: dateString ?? this.dateString,
      amountMl: amountMl ?? this.amountMl,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
