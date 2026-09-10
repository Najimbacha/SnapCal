import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/body_metric.dart';
import '../data/services/cloud_record_sync.dart';
import '../core/services/security_service.dart';

part 'metrics_provider.g.dart';

@Riverpod(keepAlive: true)
class BodyMetrics extends _$BodyMetrics {
  static const String _boxName = 'body_metrics_box';
  Box<BodyMetric>? _box;
  final CloudRecordSync _cloud = CloudRecordSync('bodyMetrics');

  /// Progress-photo paths are files on this phone, so like meal photos they
  /// are not uploaded; the weight history itself is.
  @visibleForTesting
  static Map<String, dynamic> toCloud(BodyMetric metric) => {
    'date': metric.date.millisecondsSinceEpoch,
    'weight': metric.weight,
    'bodyFat': metric.bodyFat,
    'note': metric.note,
  };

  @visibleForTesting
  static BodyMetric? fromCloud(
    String id,
    Map<String, dynamic> data, {
    BodyMetric? local,
  }) {
    final date = data['date'];
    final weight = data['weight'];
    if (date is! num || weight is! num) return null;
    return BodyMetric(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(date.toInt()),
      weight: weight.toDouble(),
      bodyFat: (data['bodyFat'] as num?)?.toDouble(),
      note: data['note'] as String?,
      photoFrontPath: local?.photoFrontPath,
      photoSidePath: local?.photoSidePath,
    );
  }

  dynamic _keyForId(String id) {
    final box = _box;
    if (box == null) return null;
    for (final key in box.keys) {
      if (box.get(key)?.id == id) return key;
    }
    return null;
  }

  @override
  Future<List<BodyMetric>> build() async {
    if (!Hive.isBoxOpen(_boxName)) {
      final encryptionKey = await SecurityService().getEncryptionKey();
      _box = await Hive.openBox<BodyMetric>(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } else {
      _box = Hive.box<BodyMetric>(_boxName);
    }
    final list =
        _box!.values.toList()..sort((a, b) => b.date.compareTo(a.date));
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

  Future<void> logWeight(
    double weightKg, {
    DateTime? date,
    double? heightCm,
  }) async {
    if (_box == null) return;
    final metric = BodyMetric(date: date ?? DateTime.now(), weight: weightKg);
    await _box!.add(metric);
    ref.invalidateSelf();
    unawaited(
      _cloud
          .push(metric.id, toCloud(metric))
          .catchError((Object e) => debugPrint('Weight sync failed: $e')),
    );
  }

  /// Applies weigh-ins recorded on the user's other devices. Returns whether
  /// anything on this phone changed.
  Future<bool> pullFromCloud() async {
    await future;
    final box = _box;
    if (box == null) return false;
    final changed = await _cloud.pull(
      upsert: (id, data) async {
        final key = _keyForId(id);
        final local = key == null ? null : box.get(key);
        final metric = fromCloud(id, data, local: local);
        if (metric == null) return false;
        if (local != null &&
            local.date == metric.date &&
            local.weight == metric.weight &&
            local.bodyFat == metric.bodyFat &&
            local.note == metric.note) {
          return false;
        }
        if (key == null) {
          await box.add(metric);
        } else {
          await box.put(key, metric);
        }
        return true;
      },
      delete: (id) async {
        final key = _keyForId(id);
        if (key == null) return false;
        await box.delete(key);
        return true;
      },
    );
    if (changed) ref.invalidateSelf();
    return changed;
  }

  /// Uploads every weigh-in on this phone to the signed-in account.
  Future<void> pushAllLocal() async {
    await future;
    final box = _box;
    if (box == null) return;
    await _cloud.pushAll({
      for (final metric in box.values) metric.id: toCloud(metric),
    });
  }

  Future<void> logProgressPhoto(String filePath) async {
    final list = state.valueOrNull ?? [];
    final canAdd = list.where((m) => m.photoFrontPath != null).length < 3;
    if (!canAdd) throw Exception('Free tier limit: max 3 progress photos');
  }
}
