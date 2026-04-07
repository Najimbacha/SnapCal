import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/body_metric.dart';
import 'settings_provider.dart';

class MetricsProvider with ChangeNotifier {
  static const String _boxName = 'body_metrics_box';
  Box<BodyMetric>? _box;
  SettingsProvider _settingsProvider;

  MetricsProvider(this._settingsProvider) {
    _init();
  }

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    notifyListeners();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<BodyMetric> _metrics = [];
  List<BodyMetric> get metrics => _metrics;

  Future<void> _init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<BodyMetric>(_boxName);
    } else {
      _box = Hive.box<BodyMetric>(_boxName);
    }
    _sortMetrics(); // Load without notifying
    _isLoading = false;
    notifyListeners(); // Single notify after full init
  }

  /// Sort/reload metrics from box without notifying listeners
  void _sortMetrics() {
    if (_box == null) return;
    _metrics =
        _box!.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  void _loadMetrics() {
    _sortMetrics();
    notifyListeners();
  }

  /// Add or update a weight entry
  Future<void> logWeight(
    double weight, {
    double? bodyFat,
    DateTime? date,
  }) async {
    final entryDate = date ?? DateTime.now();

    // Check if entry exists for this day
    final existingIndex = _metrics.indexWhere(
      (m) =>
          m.date.year == entryDate.year &&
          m.date.month == entryDate.month &&
          m.date.day == entryDate.day,
    );

    if (existingIndex != -1) {
      final existing = _metrics[existingIndex];
      final updated = existing.copyWith(
        weight: weight,
        bodyFat: bodyFat ?? existing.bodyFat,
        date: entryDate,
      );
      await _box?.put(existing.key, updated);
    } else {
      final newMetric = BodyMetric(
        date: entryDate,
        weight: weight,
        bodyFat: bodyFat,
      );
      await _box?.add(newMetric);
    }

    _loadMetrics();

    // Auto-recalculate nutrition plan with new weight
    _settingsProvider.recalculatePlan(currentWeightKg: weight);
  }

  /// Delete an entry
  Future<void> deleteMetric(String id) async {
    final metric = _metrics.firstWhere((m) => m.id == id);
    await metric.delete();
    _loadMetrics();
  }

  /// Get current weight (latest entry)
  double? get currentWeight {
    if (_metrics.isEmpty) return null;
    return _metrics.first.weight;
  }

  /// Get starting weight (first entry)
  double? get startWeight {
    if (_metrics.isEmpty) return null;
    return _metrics.last.weight; // Since list is sorted newest first
  }

  /// Calculate BMI
  double? get bmi {
    final weight = currentWeight;
    final heightCm = _settingsProvider.settings.height;

    if (weight == null || heightCm == null || heightCm == 0) return null;

    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  /// Get BMI Category
  String get bmiCategory {
    final val = bmi;
    if (val == null) return 'Unknown';
    if (val < 18.5) return 'Underweight';
    if (val < 25) return 'Normal';
    if (val < 30) return 'Overweight';
    return 'Obese';
  }

  /// Get weight trend data (last 30 days)
  List<BodyMetric> get recentTrend {
    return _metrics.take(30).toList(); // Already sorted newest first
  }
}
