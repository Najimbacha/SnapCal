import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/app_review_service.dart';
import '../../data/services/premium_gate_service.dart';
import '../../data/services/promotional_paywall_service.dart';
import '../../data/services/scan_gate_service.dart';
import 'security_service.dart';

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
    'upload_queue_box',
    'activity_box',
  ];

  Future<void> clearLocalUserData({bool wipeSecurityKeys = false}) async {
    debugPrint(
      '🧹 SessionCleanupService: clearing local user data '
      '(wipeSecurityKeys=$wipeSecurityKeys)',
    );

    for (final name in _encryptedBoxes) {
      await _clearEncryptedBox(name);
    }
    for (final name in _plainBoxes) {
      await _clearPlainBox(name);
    }

    await _clearGatePreferences();

    if (wipeSecurityKeys) {
      try {
        for (final name in [..._encryptedBoxes, ..._plainBoxes]) {
          if (Hive.isBoxOpen(name)) {
            await Hive.box<dynamic>(name).close();
          }
          await Hive.deleteBoxFromDisk(name);
        }
      } catch (e) {
        debugPrint('🧹 SessionCleanupService: box deletion skipped: $e');
      }
      try {
        await SecurityService().clearKeys();
      } catch (e) {
        debugPrint('🧹 SessionCleanupService: key cleanup failed: $e');
      }
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

  Future<void> _clearEncryptedBox(String name) async {
    try {
      final box =
          Hive.isBoxOpen(name)
              ? Hive.box<dynamic>(name)
              : await Hive.openBox<dynamic>(
                name,
                encryptionCipher: HiveAesCipher(
                  await SecurityService().getEncryptionKey(),
                ),
              );
      await box.clear();
    } catch (e) {
      debugPrint('🧹 SessionCleanupService: clear "$name" failed: $e');
    }
  }

  Future<void> _clearPlainBox(String name) async {
    try {
      final box =
          Hive.isBoxOpen(name)
              ? Hive.box<dynamic>(name)
              : await Hive.openBox<dynamic>(name);
      await box.clear();
    } catch (e) {
      debugPrint('🧹 SessionCleanupService: clear "$name" failed: $e');
    }
  }
}
