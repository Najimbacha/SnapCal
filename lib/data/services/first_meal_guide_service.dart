import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/pref_scoping.dart';

/// Persists the small, optional Home hint shown after onboarding.
///
/// The flag is local and user-scoped: it is only scheduled by a newly
/// completed onboarding flow, so existing users are never interrupted by it.
class FirstMealGuideService {
  static final FirstMealGuideService _instance =
      FirstMealGuideService._internal();

  factory FirstMealGuideService() => _instance;
  FirstMealGuideService._internal();

  static const _pendingKey = 'first_meal_guide_pending_v1';

  Future<void> schedule() => _writePending(true);

  Future<void> dismiss() => _writePending(false);

  Future<void> markCompleted() => _writePending(false);

  Future<bool> isPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(scopedPrefKey(_pendingKey)) ?? false;
    } catch (error) {
      debugPrint('First meal guide state could not be read: $error');
      return false;
    }
  }

  Future<void> _writePending(bool pending) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = scopedPrefKey(_pendingKey);
      if (pending) {
        await prefs.setBool(key, true);
      } else {
        await prefs.remove(key);
      }
    } catch (error) {
      debugPrint('First meal guide state could not be saved: $error');
    }
  }
}
