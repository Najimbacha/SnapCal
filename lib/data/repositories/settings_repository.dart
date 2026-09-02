import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/security_service.dart';
import '../../core/utils/pref_scoping.dart';
import '../../core/resilience/timeout_policy.dart';
import '../models/user_settings.dart';
import '../../core/constants/app_constants.dart';
import '../services/sync_queue_service.dart';

/// Repository for managing user settings in Hive and Firestore.
///
/// Deliberately a singleton. Every instance owns its own broadcast
/// [StreamController], so a second instance would emit settings changes that
/// no widget is listening to: `SubscriptionService` writes Pro status through
/// the instance built in `AppInitializer`, while `settingsProvider` watches
/// the one built by `settingsRepositoryProvider`. When those were two objects,
/// a completed purchase updated Hive but never reached the UI until the app
/// was relaunched. One instance, one stream, one source of truth.
class SettingsRepository {
  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  Box<UserSettings>? _settingsBox;
  final _settingsController = StreamController<UserSettings>.broadcast();
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSubscription;
  Future<void>? _initFuture;
  bool _initialized = false;

  FirebaseFirestore get _firestoreClient =>
      _firestore ??= FirebaseFirestore.instance;
  FirebaseAuth get _authClient => _auth ??= FirebaseAuth.instance;

  /// Stream of user settings for reactive UI updates
  Stream<UserSettings> get settingsStream => _settingsController.stream;

  /// Initialize the repository
  Future<void> init() async {
    if (_initialized) return;
    final existingInit = _initFuture;
    if (existingInit != null) return existingInit;

    final initFuture = _initInternal();
    _initFuture = initFuture;
    try {
      await initFuture;
      _initialized = true;
    } finally {
      if (!_initialized) _initFuture = null;
    }
  }

  Future<void> _initInternal() async {
    _firestore ??= FirebaseFirestore.instance;
    _auth ??= FirebaseAuth.instance;
    try {
      final encryptionKey = await SecurityService().getEncryptionKey();
      _settingsBox = await Hive.openBox<UserSettings>(
        AppConstants.settingsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      if (e is StateError &&
          e.message.contains('Secure storage is unavailable')) {
        rethrow;
      }
      debugPrint(
        '⚠️ SettingsRepository: Box open failed, attempting recovery: $e',
      );
      try {
        await Hive.deleteBoxFromDisk(AppConstants.settingsBoxName);
        final encryptionKey = await SecurityService().getEncryptionKey();
        _settingsBox = await Hive.openBox<UserSettings>(
          AppConstants.settingsBoxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
        debugPrint('✅ SettingsRepository: Recovery successful');
      } catch (retryError) {
        debugPrint('❌ SettingsRepository: Fatal recovery failure: $retryError');
      }
    }

    // Emit initial value
    final initialSettings = getSettings();
    _settingsController.add(initialSettings);

    await _authSubscription?.cancel();
    _authSubscription = _authClient.authStateChanges().listen((user) {
      if (user != null) {
        unawaited(syncFromFirestore());
      }
    });
  }

  /// Get current user settings (Sync)
  UserSettings getSettings() {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      return UserSettings.defaults();
    }
    return _settingsBox!.get(AppConstants.settingsKey) ??
        UserSettings.defaults();
  }

  /// Save user settings (Local + Cloud)
  Future<void> saveSettings(UserSettings settings) async {
    // 1. Save to Local Hive
    await _settingsBox?.put(AppConstants.settingsKey, settings);

    // 2. Push to Stream
    _settingsController.add(settings);

    // 3. Sync to Firestore if logged in
    final user = _authClient.currentUser;
    if (user != null) {
      final appSettingsPath = 'users/${user.uid}/settings/app';
      final profilePath = 'users/${user.uid}/private/profile';
      final appSettingsPayload = _appSettingsPayload(settings);
      final profilePayload = _profilePayload(settings);
      try {
        await Future.wait([
          _firestoreClient
              .doc(appSettingsPath)
              .set(appSettingsPayload, SetOptions(merge: true)),
          _firestoreClient
              .doc(profilePath)
              .set(profilePayload, SetOptions(merge: true)),
        ]).timeout(TimeoutPolicy.firestore);
      } catch (e) {
        debugPrint('Firestore Sync Error: $e');
        await SyncQueueService().enqueueSet(
          id: 'settings:set:${user.uid}',
          documentPath: appSettingsPath,
          data: appSettingsPayload,
        );
        await SyncQueueService().enqueueSet(
          id: 'profile:set:${user.uid}',
          documentPath: profilePath,
          data: profilePayload,
        );
      }
    }
  }

  /// How stale a device's copy of cloud settings may get before it re-reads.
  ///
  /// Settings change rarely and almost never from a second device, so pulling
  /// them on every single launch bought nothing and cost four document reads
  /// each time. Six hours keeps a genuine cross-device edit arriving the same
  /// day while removing the read from almost every launch.
  static const _cloudSyncInterval = Duration(hours: 6);
  static const _cloudSyncAtKey = 'settingsCloudSyncAt';

  /// Scoped from this repository's own auth client rather than the global
  /// `scopedPrefKey()`, which reads `FirebaseAuth.instance`. The format is
  /// identical, so `prefKeyBelongsTo` still matches it — but the repository
  /// takes an injectable auth client, and a test that swaps it must not end up
  /// reading one user's key while writing another's.
  String _cloudSyncKeyFor(String uid) => '$uid:$_cloudSyncAtKey';

  /// Pull settings from Firestore.
  ///
  /// Three behaviours, in order of cost:
  ///
  ///  * No record of ever syncing this account on this device — a fresh
  ///    install, or a different user signing in — reads everything, including
  ///    the legacy blob on the user root. Four reads. This case must never be
  ///    skipped: it is how a new device gets the user's data at all.
  ///  * Synced recently — reads nothing and returns. Local storage is already
  ///    the source of truth for display.
  ///  * Synced a while ago — reads the three live documents but not the legacy
  ///    root, which only matters on a first migration. Three reads.
  ///
  /// Pass [force] to bypass the interval where a caller genuinely needs the
  /// current cloud state, such as an explicit pull-to-refresh.
  ///
  /// The key is UID-scoped, so signing in as a different user on a shared
  /// device always takes the first-sync path rather than inheriting someone
  /// else's freshness.
  Future<void> syncFromFirestore({bool force = false}) async {
    final user = _authClient.currentUser;
    if (user == null) return;

    SharedPreferences? prefs;
    int? lastSyncMs;
    try {
      prefs = await SharedPreferences.getInstance();
      lastSyncMs = prefs.getInt(_cloudSyncKeyFor(user.uid));
    } catch (_) {
      // Unavailable in unit tests and on a broken platform channel. Treat it
      // as "never synced": correct, just not cheap.
      lastSyncMs = null;
    }

    final isFirstSync = lastSyncMs == null;

    // Compared against `lastSyncMs` directly rather than through `isFirstSync`:
    // Dart only promotes a nullable local from an explicit null check, not
    // through a boolean that happens to hold the result of one.
    if (!force && lastSyncMs != null) {
      final age = DateTime.now().millisecondsSinceEpoch - lastSyncMs;
      if (age < _cloudSyncInterval.inMilliseconds) return;
    }

    try {
      final rootRef = _firestoreClient.collection('users').doc(user.uid);
      final docs = await Future.wait([
        rootRef.collection('settings').doc('app').get(),
        rootRef.collection('private').doc('profile').get(),
        rootRef.collection('subscription').doc('current').get(),
        // Only on a first sync. This is a compatibility path for settings that
        // used to live on the user root; once merged, re-reading it every time
        // is a document read that can never contain anything new.
        if (isFirstSync) rootRef.get(),
      ]).timeout(TimeoutPolicy.firestore);

      final appSettings = docs[0].data() ?? const <String, dynamic>{};
      final profile = docs[1].data() ?? const <String, dynamic>{};
      final subscriptionSnap = docs[2];
      // Written as a statement, not a ternary. Inside a conditional expression
      // the parser reads the `?` of `data()?['settings']` as a second `?:`
      // rather than as the null-aware index, and the line stops compiling.
      Object? legacySettings;
      if (docs.length > 3) {
        legacySettings = docs[3].data()?['settings'];
      }
      if (appSettings.isNotEmpty ||
          profile.isNotEmpty ||
          legacySettings is Map<String, dynamic>) {
        final localSettings = getSettings();

        // Field-wise merge, not wholesale replacement.
        //
        // The two upload payloads do not carry every field (recommendation
        // copy, plan pace, dietary notes, ...). Building the merged object
        // from cloud data alone meant every absent key fell back to its
        // default and then overwrote a perfectly good local value — silent
        // data loss on every sign-in. Local values are the base; the cloud
        // only overrides keys it actually has.
        final cloudJson = <String, dynamic>{
          if (legacySettings is Map<String, dynamic>) ...legacySettings,
          ...profile,
          ...appSettings,
        }..removeWhere((_, value) => value == null);

        // `isPro` is server-owned, but "document not found" is not the same
        // answer as "not subscribed". A missing subscription doc (webhook
        // lag, first launch after purchase) must leave Pro exactly as it is.
        final subscriptionData = subscriptionSnap.data();
        final serverPro =
            subscriptionSnap.exists
                ? subscriptionData != null &&
                    subscriptionData['isActive'] == true
                : localSettings.isPro;

        final mergedSettings = UserSettings.fromJson({
          ...localSettings.toJson(),
          ...cloudJson,
        }).copyWith(isPro: serverPro);

        // Compare merged settings with local settings using mapEquals to avoid redundant writes
        if (!mapEquals(mergedSettings.toJson(), localSettings.toJson())) {
          await _settingsBox?.put(AppConstants.settingsKey, mergedSettings);
          _settingsController.add(mergedSettings);
        }
      }

      // Recorded only after the merge succeeded. Stamping it earlier would
      // make a failed sync look like a completed one and suppress the retry
      // for six hours.
      await prefs?.setInt(
        _cloudSyncKeyFor(user.uid),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Cursor deliberately not advanced: the next launch tries again.
      debugPrint('Firestore Pull Error: $e');
    }
  }

  /// Update daily calorie goal
  Future<void> updateCalorieGoal(int goal) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(dailyCalorieGoal: goal));
  }

  /// Update protein goal
  Future<void> updateProteinGoal(int goal) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(dailyProteinGoal: goal));
  }

  /// Update carb goal
  Future<void> updateCarbGoal(int goal) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(dailyCarbGoal: goal));
  }

  /// Update fat goal
  Future<void> updateFatGoal(int goal) async {
    final settings = getSettings();
    await saveSettings(settings.copyWith(dailyFatGoal: goal));
  }

  /// Update pro status
  Future<void> updateProStatus(bool isPro) async {
    final settings = getSettings();
    final updated = settings.copyWith(isPro: isPro);
    await _settingsBox?.put(AppConstants.settingsKey, updated);
    _settingsController.add(updated);
  }

  /// Update streak
  Future<void> updateStreak(int streak, String lastLoggedDate) async {
    final settings = getSettings();
    await saveSettings(
      settings.copyWith(currentStreak: streak, lastLoggedDate: lastLoggedDate),
    );
  }

  /// Check if user is pro
  bool isPro() => getSettings().isPro;

  /// Get current streak
  int getCurrentStreak() => getSettings().currentStreak;

  /// Clear all settings (logout)
  Future<void> clear() async {
    await _settingsBox?.clear();

    // The cloud-sync stamp must go with the data it describes. Leaving it
    // behind means a user who signs back in within the sync interval is told
    // their settings are fresh when local storage is empty — they would sit on
    // defaults, with their real settings in Firestore, until the stamp aged
    // out six hours later.
    //
    // Every scoped variant is removed, not just the current user's. `clear()`
    // can run either side of sign-out, so there may be no uid left to build
    // the key from — and removing a bare or wrong key would leave the real,
    // UID-scoped stamp in place and reintroduce exactly the bug above.
    try {
      final prefs = await SharedPreferences.getInstance();
      final stale =
          prefs
              .getKeys()
              .where((k) => prefKeyBelongsTo(k, _cloudSyncAtKey))
              .toList();
      for (final key in stale) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Best effort. A failure here costs a stale window, not data.
    }

    _settingsController.add(UserSettings.defaults());
  }

  void dispose() {
    _authSubscription?.cancel();
    _settingsController.close();
  }

  Map<String, dynamic> _appSettingsPayload(UserSettings settings) {
    return {
      'themeMode': settings.themeMode,
      'languageCode': settings.languageCode,
      'onboardingComplete': settings.onboardingComplete,
      'notificationsEnabled': settings.notificationsEnabled,
      'mealRemindersEnabled': settings.mealRemindersEnabled,
      'dailyMotivationEnabled': settings.dailyMotivationEnabled,
      'goalAlertsEnabled': settings.goalAlertsEnabled,
      'foodRemindersEnabled': settings.foodRemindersEnabled,
      'recommendationInsight': settings.recommendationInsight,
      'recommendationTip': settings.recommendationTip,
      'recommendationSafetyNote': settings.recommendationSafetyNote,
      'fcmToken': settings.fcmToken,
      // `lastFoodReminderDate` is deliberately absent. Reminder tracking moved
      // to the server-owned `serverReminderSentOn`, which no client writes;
      // this field is now dead. Sending it did real harm while it was the
      // tracking field -- the payload carries whatever the local copy holds,
      // which is null until a cloud pull has happened, so a user who changed
      // their theme after the morning reminder erased the server's date and
      // became eligible again the same day. Older app versions still send it
      // and that is harmless: nothing reads it.
      'currentStreak': settings.currentStreak,
      'lastLoggedDate': settings.lastLoggedDate,
      'lastOpenedDate': settings.lastOpenedDate,
      'breakfastTime': settings.breakfastTime,
      'lunchTime': settings.lunchTime,
      'dinnerTime': settings.dinnerTime,
      'weightUnit': settings.weightUnit,
      'heightUnit': settings.heightUnit,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _profilePayload(UserSettings settings) {
    return {
      'age': settings.age,
      'height': settings.height,
      // Written under its own name. This used to be uploaded as `weight`
      // while `fromJson` read `startingWeight`, so the baseline never made it
      // back down and every cloud pull reset it to null. `weight` is still
      // written for one release so older clients keep reading something.
      'startingWeight': settings.startingWeight,
      'weight': settings.startingWeight,
      'targetWeight': settings.targetWeight,
      'dailyCalorieGoal': settings.dailyCalorieGoal,
      'dailyProteinGoal': settings.dailyProteinGoal,
      'dailyCarbGoal': settings.dailyCarbGoal,
      'dailyFatGoal': settings.dailyFatGoal,
      'gender': settings.gender,
      'activityLevel': settings.activityLevel,
      'goalMode': settings.goalMode,
      'goalTimelineMonths': settings.goalTimelineMonths,
      'weeklyRateKg': settings.weeklyRateKg,
      'dietaryRestriction': settings.dietaryRestriction,
      'cuisinePreference': settings.cuisinePreference,
      'foodDislikes': settings.foodDislikes,
      'medicalNotes': settings.medicalNotes,
      'mealsPerDay': settings.mealsPerDay,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
