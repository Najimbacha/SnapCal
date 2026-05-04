import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/security_service.dart';
import '../../core/constants/app_constants.dart';
import '../services/assistant_service.dart';

class AssistantRepository {
  Box? _box;

  Future<void> init() async {
    final encryptionKey = await SecurityService().getEncryptionKey();
    _box = await Hive.openBox(
      AppConstants.assistantBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  /// Get cached recommendations if they exist
  List<AssistantResponse>? getCachedRecommendations() {
    final data = _box?.get('cached_recommendations');
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
    await _box?.put('cached_recommendations', jsonEncode(jsonList));
  }

  /// Get the calorie snapshot from the last fetch
  int getLastCalorieSnapshot() {
    return _box?.get('last_calorie_snapshot') ?? -999;
  }

  /// Save current calorie snapshot
  Future<void> saveCalorieSnapshot(int calories) async {
    await _box?.put('last_calorie_snapshot', calories);
  }

  /// Get full chat history
  List<dynamic>? getChatHistory() {
    final data = _box?.get('chat_history');
    if (data == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) {
        final map = e as Map<String, dynamic>;
        if (map['type'] == 'user') return map;
        return AssistantResponse.fromJson(map);
      }).toList();
    } catch (e) {
      return null;
    }
  }

  /// Save full chat history
  Future<void> saveChatHistory(List<dynamic> history) async {
    final jsonList = history.map((e) {
      if (e is Map) return e;
      final res = e as AssistantResponse;
      return {
        'title': res.title,
        'content': res.content,
        'type': res.type,
        'macros': res.macros,
        'actions': res.actions?.map((a) => a.toJson()).toList(),
      };
    }).toList();
    await _box?.put('chat_history', jsonEncode(jsonList));
  }

  /// Clear all cache and history
  Future<void> clearCache() async {
    await _box?.delete('cached_recommendations');
    await _box?.delete('last_calorie_snapshot');
    await _box?.delete('chat_history');
  }
}
