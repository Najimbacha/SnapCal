import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/app_review_service.dart';
import '../../data/services/premium_gate_service.dart';
import '../../data/services/promotional_paywall_service.dart';
import '../../data/services/scan_gate_service.dart';
import '../../data/models/meal.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/water_log.dart';
import '../../data/models/body_metric.dart';
import '../../data/models/meal_plan.dart';
import '../../data/models/grocery_item.dart';
import '../../data/models/meal_template.dart';
import '../../data/models/achievement.dart';
import 'security_service.dart';
import 'session_data_guard.dart';

/// Clears every user-scoped local store when a session ends (BUG-002).
///
/// Provider invalidation is not enough: the providers rebuild from the same
/// encrypted Hive boxes, so without an explicit wipe the next account on the
/// device sees the previous user's meals, weight history, chat transcript,
/// goals and streak. This service is invoked from the auth flows — before any
/// navigation happens — and is idempotent.
///
/// [wipeSecurityKeys] additionally removes the Hive encryption key and the box
/// files themselves. Used by account deletion, where nothing of the old user
/// may remain on disk. Because the encrypted boxes are cleared first, a later
/// cipher mismatch on a leftover file is impossible in practice; the
/// repositories' corrupt-box recovery path remains as a final safety net.
class SessionCleanupService {
  static final SessionCleanupService _instance =
      SessionCleanupService._internal();
  factory SessionCleanupService() => _instance;
  SessionCleanupService._internal();

  /// AES-encrypted user-data boxes. Must match how each box is opened by its
  /// owning repository/provider.
  static const List<String> _encryptedBoxes = [
    // AppConstants.mealsBoxName / mealIndexBoxName / settingsBoxName /
    // waterBoxName / assistantBoxName are referenced here by literal to avoid
    // a circular import with the constants file used by repositories.
    'meals_box',
    'meal_index_box',
    'settings_box',
    'water_box',
    'assistant_box',
    'body_metrics_box',
  ];

  /// Unencrypted state boxes (planner, templates, achievements, queues,
  /// activity/manual-workout history).
  static const List<String> _plainBoxes = [
    'meal_plan_box',
    'grocery_list_box',
    'templates_box',
    'achievements_box',
    'sync_queue_box',
    'sync_cursor_box',
    'upload_queue_box',
    'activity_box',
  ];

  Future<void> clearLocalUserData({
    bool wipeSecurityKeys = false,
    Future<void> Function()? finishSession,
  }) => SessionDataGuard.instance.cleanup(() async {
    await _clearLocalUserData(wipeSecurityKeys: wipeSecurityKeys);
    // Keep downloads suspended until Firebase has switched identities too.
    // Otherwise a fresh old-account pull can start just after the wipe.
    await finishSession?.call();
  });

  Future<void> _clearLocalUserData({required bool wipeSecurityKeys}) async {
    debugPrint(
      '🧹 SessionCleanupService: clearing local user data '
      '(wipeSecurityKeys=$wipeSecurityKeys)',
    );

    final boxes = <Box>[];
    for (final name in [..._encryptedBoxes, ..._plainBoxes]) {
      final box = await _openUserBox(name);
      await box.clear();
      boxes.add(box);
    }
    await _clearGatePreferences();

    if (wipeSecurityKeys) {
      for (final box in boxes) {
        final name = box.name;
        await box.close();
        await Hive.deleteBoxFromDisk(name);
      }
      // Rotate only after every encrypted file has been removed.
      await SecurityService().clearKeys();
    }

    debugPrint('🧹 SessionCleanupService: done');
  }

  /// Belt-and-braces sweep of every preference key that could carry per-user
  /// state, on top of the per-service resets.
  Future<void> _clearGatePreferences() async {
    try {
      await ScanGateService().resetSessionState();
    } catch (e) {
      debugPrint('🧹 Scan gate reset failed: $e');
    }
    try {
      await PremiumGateService().resetSessionState();
    } catch (e) {
      debugPrint('🧹 Premium gate reset failed: $e');
    }
    try {
      await PromotionalPaywallService.instance().resetSessionState();
    } catch (e) {
      debugPrint('🧹 Promotional paywall reset failed: $e');
    }
    try {
      await AppReviewService.instance().resetSessionState();
    } catch (e) {
      debugPrint('🧹 App review reset failed: $e');
    }

    // Sweep anything left over under known prefixes (legacy or scoped keys).
    try {
      final prefs = await SharedPreferences.getInstance();
      const prefixes = [
        'scanCount_',
        'scanGate_',
        'bonusScansCount',
        'last_premium_popup_date',
        'premium_popup_count_today',
        'last_upgrade_tap_timestamp',
        'last_premium_prompt_timestamp',
        'last_premium_prompt_dismissed_timestamp',
        'ai_messages_used_today',
        'free_scans_used_today',
        'promo_paywall_',
        'review_',
        'first_meal_guide_',
        'quick_food_',
        // SettingsRepository's per-account 'synced recently' marker. Left behind,
        // signing back in within its interval skipped the settings pull, so an
        // emptied phone showed default goals and sent the user to onboarding.
        'settingsCloudSyncAt',
      ];
      final stale =
          prefs
              .getKeys()
              .where((k) => prefixes.any((p) => k.contains(p) || k.endsWith(p)))
              .toList();
      for (final k in stale) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('🧹 Preference sweep failed: $e');
    }
  }

  /// Hive checks its declared value type exactly; `box<dynamic>` cannot access
  /// a box opened as `box<Meal>`, even though Box itself is covariant.
  Future<Box> _openUserBox(String name) => switch (name) {
    'meals_box' => _open<Meal>(name, encrypted: true),
    'meal_index_box' => _open<List<String>>(name, encrypted: true),
    'settings_box' => _open<UserSettings>(name, encrypted: true),
    'water_box' => _open<WaterLog>(name, encrypted: true),
    'body_metrics_box' => _open<BodyMetric>(name, encrypted: true),
    'assistant_box' => _open<dynamic>(name, encrypted: true),
    'meal_plan_box' => _open<MealPlan>(name),
    'grocery_list_box' => _open<GroceryItem>(name),
    'templates_box' => _open<MealTemplate>(name),
    'achievements_box' => _open<Achievement>(name),
    'sync_queue_box' ||
    'sync_cursor_box' ||
    'upload_queue_box' ||
    'activity_box' => _open<dynamic>(name),
    _ => throw StateError('Unknown user data box: $name'),
  };

  Future<Box<T>> _open<T>(String name, {bool encrypted = false}) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return Hive.openBox<T>(
      name,
      encryptionCipher:
          encrypted
              ? HiveAesCipher(await SecurityService().getEncryptionKey())
              : null,
    );
  }
}
