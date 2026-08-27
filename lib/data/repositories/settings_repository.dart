import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/security_service.dart';
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

  /// Pull settings from Firestore
  Future<void> syncFromFirestore() async {
    final user = _authClient.currentUser;
    if (user == null) return;

    try {
      final rootRef = _firestoreClient.collection('users').doc(user.uid);
      final docs = await Future.wait([
        rootRef.collection('settings').doc('app').get(),
        rootRef.collection('private').doc('profile').get(),
        rootRef.collection('subscription').doc('current').get(),
        rootRef.get(),
      ]).timeout(TimeoutPolicy.firestore);

      final appSettings = docs[0].data() ?? const <String, dynamic>{};
      final profile = docs[1].data() ?? const <String, dynamic>{};
      final subscriptionSnap = docs[2];
      final legacySettings = docs[3].data()?['settings'];
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
    } catch (e) {
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
      'lastFoodReminderDate': settings.lastFoodReminderDate,
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
