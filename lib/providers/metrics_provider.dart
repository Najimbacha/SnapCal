import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/body_metric.dart';
import '../data/services/cloud_record_sync.dart';
import '../core/services/security_service.dart';
import 'settings_provider.dart';

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
    double? bodyFat,
  }) async {
    if (_box == null) return;
    final metric = BodyMetric(
      date: date ?? DateTime.now(),
      weight: weightKg,
      bodyFat: bodyFat,
    );
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

  /// How many photo check-ins the free tier keeps; Pro has no ceiling.
  static const int freePhotoCheckIns = 3;

  /// Saves a photo check-in.
  ///
  /// Nothing did before. The old `logProgressPhoto` checked the free-tier
  /// limit and returned, so both photos were dropped the moment the capture
  /// screen popped: the Progress screen never had a photo to show, the
  /// comparison sheet had nothing to compare, and the check-in badges could
  /// not be earned. It also refused a fourth check-in to Pro users.
  ///
  /// The photos join today's weigh-in when there is one. Otherwise a new
  /// entry carries the last known weight forward, so the trend chart is not
  /// handed a zero for the day.
  Future<void> logProgressPhotos({String? frontPath, String? sidePath}) async {
    if (frontPath == null && sidePath == null) return;
    await future;
    final box = _box;
    if (box == null) return;

    final metrics =
        box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    final checkIns =
        metrics
            .where((m) => m.photoFrontPath != null || m.photoSidePath != null)
            .length;
    if (!ref.read(effectiveIsProProvider) && checkIns >= freePhotoCheckIns) {
      throw StateError(
        'Free tier limit: max $freePhotoCheckIns progress photo check-ins',
      );
    }

    final now = DateTime.now();
    final latest = metrics.isEmpty ? null : metrics.first;
    final BodyMetric saved;
    if (latest != null && _sameDay(latest.date, now)) {
      saved = latest.copyWith(photoFrontPath: frontPath, photoSidePath: sidePath);
      final key = _keyForId(latest.id);
      if (key == null) {
        await box.add(saved);
      } else {
        await box.put(key, saved);
      }
    } else {
      // Awaited, not `valueOrNull`: settings may still be loading, and a
      // check-in saved then was given a weight of 0.
      double? profileWeight;
      if (latest == null) {
        try {
          profileWeight = (await ref.read(settingsProvider.future)).startingWeight;
        } catch (e) {
          debugPrint('Check-in: settings unavailable: $e');
        }
      }
      final weight = latest?.weight ?? profileWeight ?? 0;
      saved = BodyMetric(
        date: now,
        weight: weight,
        photoFrontPath: frontPath,
        photoSidePath: sidePath,
      );
      await box.add(saved);
    }
    ref.invalidateSelf();
    unawaited(
      _cloud
          .push(saved.id, toCloud(saved))
          .catchError((Object e) => debugPrint('Check-in sync failed: $e')),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
