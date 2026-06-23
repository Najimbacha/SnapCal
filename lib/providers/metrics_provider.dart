import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/body_metric.dart';
import '../core/services/security_service.dart';
import '../data/services/upload_queue_service.dart';

part 'metrics_provider.g.dart';

@Riverpod(keepAlive: true)
class BodyMetrics extends _$BodyMetrics {
  static const String _boxName = 'body_metrics_box';
  Box<BodyMetric>? _box;

  @override
  Future<List<BodyMetric>> build() async {
    if (!Hive.isBoxOpen(_boxName)) {
      final encryptionKey = await SecurityService().getEncryptionKey();
      _box = await Hive.openBox<BodyMetric>(_boxName, encryptionCipher: HiveAesCipher(encryptionKey));
    } else {
      _box = Hive.box<BodyMetric>(_boxName);
    }
    final list = _box!.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }

  double? get currentWeight {
    final list = state.valueOrNull;
    if (list == null || list.isEmpty) return null;
    return list.first.weight;
  }

  double? get startingWeight {
    final list = state.valueOrNull;
    if (list == null || list.isEmpty) return null;
    return list.last.weight;
  }

  Future<void> logWeight(double weightKg, {DateTime? date, double? heightCm}) async {
    if (_box == null) return;
    final metric = BodyMetric(
      date: date ?? DateTime.now(),
      weight: weightKg,
    );
    await _box!.add(metric);
    ref.invalidateSelf();
  }

  Future<void> logProgressPhoto(String filePath) async {
    final list = state.valueOrNull ?? [];
    final canAdd = list.where((m) => m.photoFrontPath != null).length < 3;
    if (!canAdd) throw Exception('Free tier limit: max 3 progress photos');
  }
}
