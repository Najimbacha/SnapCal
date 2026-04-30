import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing meal data in Hive and Firestore
class MealRepository {
  late Box<Meal> _mealsBox;
  late Box<List<String>> _indexBox;
  
  final _mealsController = StreamController<List<Meal>>.broadcast();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Stream of meals for the current date for reactive UI
  Stream<List<Meal>> get todaysMealsStream => _mealsController.stream;

  /// Initialize the repository
  Future<void> init() async {
    _mealsBox = await Hive.openBox<Meal>(AppConstants.mealsBoxName);
    _indexBox = await Hive.openBox<List<String>>(AppConstants.mealIndexBoxName);

    // Initial migration: if meals exist but index is empty
    if (_mealsBox.isNotEmpty && _indexBox.isEmpty) {
      debugPrint('📦 MealRepository: Rebuilding date index...');
      final Map<String, List<String>> tempIndex = {};

      for (final meal in _mealsBox.values) {
        final date = meal.dateString;
        if (!tempIndex.containsKey(date)) {
          tempIndex[date] = [];
        }
        if (!tempIndex[date]!.contains(meal.id)) {
          tempIndex[date]!.add(meal.id);
        }
      }

      // Batch save the reconstructed index
      await _indexBox.putAll(tempIndex);
      debugPrint('✅ MealRepository: Index rebuilt successfully');
    }

    // Emit initial today's meals
    _emitTodaysMeals();

    // Initial cloud sync
    if (_auth.currentUser != null) {
      unawaited(syncFromFirestore());
    }
  }

  void _emitTodaysMeals() {
    _mealsController.add(getTodaysMeals());
  }

  /// Get all meals
  List<Meal> getAllMeals() {
    return _mealsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get meals for a specific date
  List<Meal> getMealsByDate(String dateString) {
    final ids = _indexBox.get(dateString) ?? [];
    if (ids.isEmpty) return [];

    return ids.map((id) => _mealsBox.get(id)).whereType<Meal>().toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get today's meals
  List<Meal> getTodaysMeals() {
    final today = _getDateString(DateTime.now());
    return getMealsByDate(today);
  }

  /// Add a new meal
  Future<void> addMeal(Meal meal) async {
    await _mealsBox.put(meal.id, meal);

    // Update index
    final date = meal.dateString;
    final ids = _indexBox.get(date) ?? [];
    if (!ids.contains(meal.id)) {
      ids.add(meal.id);
      await _indexBox.put(date, ids);
    }
    
    _emitTodaysMeals();
    await _syncMealToCloud(meal);
  }

  /// Update an existing meal
  Future<void> updateMeal(Meal meal) async {
    final oldMeal = _mealsBox.get(meal.id);
    await _mealsBox.put(meal.id, meal);

    // If date changed, update index
    if (oldMeal != null && oldMeal.dateString != meal.dateString) {
      final oldDate = oldMeal.dateString;
      final oldIds = _indexBox.get(oldDate) ?? [];
      oldIds.remove(meal.id);
      if (oldIds.isEmpty) {
        await _indexBox.delete(oldDate);
      } else {
        await _indexBox.put(oldDate, oldIds);
      }

      final newDate = meal.dateString;
      final newIds = _indexBox.get(newDate) ?? [];
      if (!newIds.contains(meal.id)) {
        newIds.add(meal.id);
        await _indexBox.put(newDate, newIds);
      }
    }
    
    _emitTodaysMeals();
    await _syncMealToCloud(meal);
  }

  /// Delete a meal
  Future<void> deleteMeal(String id) async {
    final meal = _mealsBox.get(id);
    if (meal != null) {
      final date = meal.dateString;
      final ids = _indexBox.get(date) ?? [];
      ids.remove(id);
      if (ids.isEmpty) {
        await _indexBox.delete(date);
      } else {
        await _indexBox.put(date, ids);
      }
      
      _emitTodaysMeals();
      await _deleteMealFromCloud(id);
    }
    await _mealsBox.delete(id);
  }

  /// Sync single meal to Firestore
  Future<void> _syncMealToCloud(Meal meal) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .doc(meal.id)
          .set(meal.toJson());
    } catch (e) {
      debugPrint('Meal Sync Error: $e');
    }
  }

  /// Delete meal from Firestore
  Future<void> _deleteMealFromCloud(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Meal Delete Sync Error: $e');
    }
  }

  /// Pull all meals from Firestore
  Future<void> syncFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .get();
          
      for (var doc in snapshot.docs) {
        final cloudMeal = Meal.fromJson(doc.data());
        if (!_mealsBox.containsKey(cloudMeal.id)) {
          await addMeal(cloudMeal);
        }
      }
    } catch (e) {
      debugPrint('Meal Pull Error: $e');
    }
  }

  /// Get meal by ID
  Meal? getMealById(String id) => _mealsBox.get(id);

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
    await _mealsBox.clear();
    await _indexBox.clear();
    _emitTodaysMeals();
  }

  void dispose() {
    _mealsController.close();
  }
}
