import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../services/assistant_service.dart';

class AssistantRepository {
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.assistantBoxName);
  }

  /// Get cached recommendations if they exist
  List<AssistantResponse>? getCachedRecommendations() {
    final data = _box.get('cached_recommendations');
    if (data == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList
          .map((e) => AssistantResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Save recommendations to cache
  Future<void> saveRecommendations(
    List<AssistantResponse> recommendations,
  ) async {
    final jsonList =
        recommendations
            .map(
              (e) => {
                'title': e.title,
                'content': e.content,
                'type': e.type,
                'macros': e.macros,
              },
            )
            .toList();
    await _box.put('cached_recommendations', jsonEncode(jsonList));
  }

  /// Get the calorie snapshot from the last fetch
  int getLastCalorieSnapshot() {
    return _box.get('last_calorie_snapshot') ?? -999;
  }

  /// Save current calorie snapshot
  Future<void> saveCalorieSnapshot(int calories) async {
    await _box.put('last_calorie_snapshot', calories);
  }

  /// Clear cache (e.g., on manual refresh)
  Future<void> clearCache() async {
    await _box.delete('cached_recommendations');
    await _box.delete('last_calorie_snapshot');
  }
}
