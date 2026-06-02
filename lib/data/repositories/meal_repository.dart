import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/security_service.dart';
import '../../core/resilience/timeout_policy.dart';
import '../models/meal.dart';
import '../../core/constants/app_constants.dart';
import '../services/sync_queue_service.dart';

/// Repository for managing meal data in Hive and Firestore
class MealRepository {
  Box<Meal>? _mealsBox;
  Box<List<String>>? _indexBox;

  final _mealsController = StreamController<List<Meal>>.broadcast();
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSubscription;
  Future<void>? _initFuture;
  bool _initialized = false;

  FirebaseFirestore get _firestoreClient =>
      _firestore ??= FirebaseFirestore.instance;
  FirebaseAuth get _authClient => _auth ??= FirebaseAuth.instance;

  /// Stream of meals for the current date for reactive UI
  Stream<List<Meal>> get todaysMealsStream => _mealsController.stream;

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
    final encryptionKey = await SecurityService().getEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);

    try {
      if (!Hive.isBoxOpen(AppConstants.mealsBoxName)) {
        _mealsBox = await Hive.openBox<Meal>(
          AppConstants.mealsBoxName,
          encryptionCipher: cipher,
        ).timeout(const Duration(seconds: 10));
      } else {
        _mealsBox = Hive.box<Meal>(AppConstants.mealsBoxName);
      }

      if (!Hive.isBoxOpen(AppConstants.mealIndexBoxName)) {
        _indexBox = await Hive.openBox<List<String>>(
          AppConstants.mealIndexBoxName,
          encryptionCipher: cipher,
        ).timeout(const Duration(seconds: 10));
      } else {
        _indexBox = Hive.box<List<String>>(AppConstants.mealIndexBoxName);
      }
    } catch (e) {
      debugPrint('⚠️ MealRepository: Box open failed, attempting recovery: $e');
      try {
        // Attempt to delete corrupted boxes and recreate
        await Hive.deleteBoxFromDisk(AppConstants.mealsBoxName);
        await Hive.deleteBoxFromDisk(AppConstants.mealIndexBoxName);

        _mealsBox = await Hive.openBox<Meal>(
          AppConstants.mealsBoxName,
          encryptionCipher: cipher,
        );
        _indexBox = await Hive.openBox<List<String>>(
          AppConstants.mealIndexBoxName,
          encryptionCipher: cipher,
        );
        debugPrint('✅ MealRepository: Recovery successful (Data cleared)');
      } catch (retryError) {
        debugPrint('❌ MealRepository: Fatal recovery failure: $retryError');
        rethrow;
      }
    }

    // Initial migration: if meals exist but index is empty
    if (_mealsBox != null &&
        _mealsBox!.isNotEmpty &&
        _indexBox != null &&
        _indexBox!.isEmpty) {
      debugPrint('📦 MealRepository: Rebuilding date index...');
      final Map<String, List<String>> tempIndex = {};

      for (final meal in _mealsBox!.values) {
        final date = meal.dateString;
        if (!tempIndex.containsKey(date)) {
          tempIndex[date] = [];
        }
        if (!tempIndex[date]!.contains(meal.id)) {
          tempIndex[date]!.add(meal.id);
        }
      }

      // Batch save the reconstructed index
      await _indexBox?.putAll(tempIndex);
      debugPrint('✅ MealRepository: Index rebuilt successfully');
    }

    // Emit initial today's meals
    _emitTodaysMeals();

    await _authSubscription?.cancel();
    _authSubscription = _authClient.authStateChanges().listen((user) {
      if (user != null) {
        unawaited(syncFromFirestore());
      }
    });
  }

  void _emitTodaysMeals() {
    _mealsController.add(getTodaysMeals());
  }

  /// Get all meals
  List<Meal> getAllMeals() {
    if (_mealsBox == null) return [];
    return _mealsBox!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get meals for a specific date
  List<Meal> getMealsByDate(String dateString) {
    if (_indexBox == null || _mealsBox == null) return [];
    final ids = _indexBox!.get(dateString) ?? [];
    if (ids.isEmpty) return [];

    return ids.map((id) => _mealsBox!.get(id)).whereType<Meal>().toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get today's meals
  List<Meal> getTodaysMeals() {
    final today = _getDateString(DateTime.now());
    return getMealsByDate(today);
  }

  /// Add a new meal
  Future<void> addMeal(Meal meal) async {
    await _saveMealLocalOnly(meal);
    _emitTodaysMeals();
    await _syncMealToCloud(meal);
  }

  Future<void> _saveMealLocalOnly(Meal meal) async {
    await _mealsBox?.put(meal.id, meal);

    if (_indexBox == null) return;
    final date = meal.dateString;
    final ids = _indexBox!.get(date) ?? [];
    if (!ids.contains(meal.id)) {
      ids.add(meal.id);
      await _indexBox!.put(date, ids);
    }
  }

  /// Update an existing meal
  Future<void> updateMeal(Meal meal) async {
    final oldMeal = _mealsBox?.get(meal.id);
    await _mealsBox?.put(meal.id, meal);

    // If date changed, update index
    if (oldMeal != null &&
        oldMeal.dateString != meal.dateString &&
        _indexBox != null) {
      final oldDate = oldMeal.dateString;
      final oldIds = _indexBox!.get(oldDate) ?? [];
      oldIds.remove(meal.id);
      if (oldIds.isEmpty) {
        await _indexBox!.delete(oldDate);
      } else {
        await _indexBox!.put(oldDate, oldIds);
      }

      final newDate = meal.dateString;
      final newIds = _indexBox!.get(newDate) ?? [];
      if (!newIds.contains(meal.id)) {
        newIds.add(meal.id);
        await _indexBox!.put(newDate, newIds);
      }
    }

    _emitTodaysMeals();
    await _syncMealToCloud(meal);
  }

  /// Delete a meal
  Future<void> deleteMeal(String id) async {
    final meal = _mealsBox?.get(id);
    if (meal != null && _indexBox != null) {
      final date = meal.dateString;
      final ids = _indexBox!.get(date) ?? [];
      ids.remove(id);
      if (ids.isEmpty) {
        await _indexBox!.delete(date);
      } else {
        await _indexBox!.put(date, ids);
      }

      _emitTodaysMeals();
      await _deleteMealFromCloud(id);
    }
    await _mealsBox?.delete(id);
  }

  /// Sync single meal to Firestore
  Future<void> _syncMealToCloud(Meal meal) async {
    final user = _authClient.currentUser;
    if (user == null) return;
    final path = 'users/${user.uid}/meals/${meal.id}';

    try {
      await _firestoreClient
          .doc(path)
          .set(meal.toJson())
          .timeout(TimeoutPolicy.firestore);
    } catch (e) {
      debugPrint('Meal Sync Error: $e');
      await SyncQueueService().enqueueSet(
        id: 'meal:set:${user.uid}:${meal.id}',
        documentPath: path,
        data: meal.toJson(),
      );
    }
  }

  /// Delete meal from Firestore
  Future<void> _deleteMealFromCloud(String id) async {
    final user = _authClient.currentUser;
    if (user == null) return;
    final path = 'users/${user.uid}/meals/$id';

    try {
      await _firestoreClient
          .doc(path)
          .delete()
          .timeout(TimeoutPolicy.firestore);
    } catch (e) {
      debugPrint('Meal Delete Sync Error: $e');
      await SyncQueueService().enqueueDelete(
        id: 'meal:delete:${user.uid}:$id',
        documentPath: path,
      );
    }
  }

  /// Pull recent meals (last 30 days) from Firestore to avoid cost spikes
  Future<void> syncFromFirestore() async {
    final user = _authClient.currentUser;
    if (user == null) return;

    try {
      final cutoff =
          DateTime.now()
              .subtract(const Duration(days: 30))
              .millisecondsSinceEpoch;
      final snapshot = await _firestoreClient
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .where('timestamp', isGreaterThanOrEqualTo: cutoff)
          .get()
          .timeout(TimeoutPolicy.firestore);

      for (var doc in snapshot.docs) {
        final cloudMeal = Meal.fromJson(doc.data());
        if (_mealsBox == null) continue;

        if (!_mealsBox!.containsKey(cloudMeal.id)) {
          // New meal from cloud — add locally
          await _saveMealLocalOnly(cloudMeal);
        } else {
          // Existing meal — update only if cloud has a newer timestamp
          // (last-saved-wins strategy using timestamp as proxy)
          final localMeal = _mealsBox!.get(cloudMeal.id);
          if (localMeal != null && cloudMeal.timestamp > localMeal.timestamp) {
            debugPrint(
              'Meal ${cloudMeal.id}: updating local copy with cloud version',
            );
            await _saveMealLocalOnly(cloudMeal);
          }
        }
      }
      _emitTodaysMeals();
    } catch (e) {
      debugPrint('Meal Pull Error: $e');
    }
  }

  /// Get meal by ID
  Meal? getMealById(String id) => _mealsBox?.get(id);

  /// Get recent meals
  List<Meal> getRecentMeals({int count = 2}) {
    final allMeals = getAllMeals();
    return allMeals.take(count).toList();
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Clear all meals
  Future<void> clearAll() async {
    await _mealsBox?.clear();
    await _indexBox?.clear();
    _emitTodaysMeals();
  }

  void dispose() {
    _authSubscription?.cancel();
    _mealsController.close();
  }
}
