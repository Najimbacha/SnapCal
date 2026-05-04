import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/security_service.dart';
import '../models/user_settings.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing user settings in Hive and Firestore
class SettingsRepository {
  Box<UserSettings>? _settingsBox;
  final _settingsController = StreamController<UserSettings>.broadcast();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Stream of user settings for reactive UI updates
  Stream<UserSettings> get settingsStream => _settingsController.stream;

  /// Initialize the repository
  Future<void> init() async {
    try {
      final encryptionKey = await SecurityService().getEncryptionKey();
      _settingsBox = await Hive.openBox<UserSettings>(
        AppConstants.settingsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('❌ SettingsRepository: Failed to open box: $e');
      // If box fails to open, we'll fall back to defaults in getSettings
    }
    
    // Emit initial value
    final initialSettings = getSettings();
    _settingsController.add(initialSettings);

    // Initial sync check
    if (_auth.currentUser != null) {
      unawaited(syncFromFirestore());
    }
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
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'settings': settings.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Silently fail or queue for later
        debugPrint('Firestore Sync Error: $e');
      }
    }
  }

  /// Pull settings from Firestore
  Future<void> syncFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['settings'] != null) {
        final cloudSettings = UserSettings.fromJson(doc.data()!['settings']);
        final localSettings = getSettings();

        // Simple conflict resolution: Cloud wins if it has data
        if (cloudSettings != localSettings) {
          await _settingsBox?.put(AppConstants.settingsKey, cloudSettings);
          _settingsController.add(cloudSettings);
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
    await saveSettings(settings.copyWith(isPro: isPro));
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
    _settingsController.close();
  }
}
