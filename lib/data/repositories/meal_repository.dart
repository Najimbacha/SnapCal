import 'dart:async';
import 'dart:io';
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
  /// Singleton: the broadcast stream below is the only channel the meal
  /// providers listen on, and a second instance (PreloadService built one)
  /// emits into a stream with no subscribers. See [SettingsRepository].
  static final MealRepository _instance = MealRepository._internal();
  factory MealRepository() => _instance;
  MealRepository._internal();

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

    // Initial migration: if meals exist but the date index is missing.
    //
    // The check is for date keys specifically, not for an empty box. The box
    // also holds the meal sync cursor, and treating that as "the index exists"
    // would skip this rebuild — leaving a user with meals in storage and no
    // date index, which reads to them as their history having vanished.
    final hasDateIndex =
        _indexBox?.keys.any(
          (k) => k is String && !k.startsWith(_cursorKeyPrefix),
        ) ??
        false;

    if (_mealsBox != null && _mealsBox!.isNotEmpty && !hasDateIndex) {
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
    final previous = _mealsBox?.get(meal.id);
    await _mealsBox?.put(meal.id, meal);

    if (_indexBox == null) return;
    // A meal edited on another device may have moved to a different day;
    // left in the old day's index it would show on both.
    if (previous != null && previous.dateString != meal.dateString) {
      await _removeFromIndex(previous.dateString, meal.id);
    }
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
    final meal = await _deleteMealLocalOnly(id);
    _emitTodaysMeals();
    if (meal == null) return;
    await _deleteMealFromCloud(id);
    await _deleteUnusedLocalImage(meal.imageUri);
  }

  Future<Meal?> _deleteMealLocalOnly(String id) async {
    final meal = _mealsBox?.get(id);
    if (meal != null) await _removeFromIndex(meal.dateString, id);
    await _mealsBox?.delete(id);
    return meal;
  }

  Future<void> _removeFromIndex(String date, String id) async {
    final index = _indexBox;
    if (index == null) return;
    final ids = index.get(date) ?? [];
    if (!ids.remove(id)) return;
    if (ids.isEmpty) {
      await index.delete(date);
    } else {
      await index.put(date, ids);
    }
  }

  Future<void> _deleteUnusedLocalImage(String? imageUri) async {
    if (imageUri == null || imageUri.startsWith('http')) return;
    final stillUsed =
        _mealsBox?.values.any((meal) => meal.imageUri == imageUri) ?? false;
    if (stillUsed) return;

    try {
      final file = File(imageUri);
      if (await file.exists()) await file.delete();
    } catch (error) {
      debugPrint('Meal thumbnail cleanup failed: $error');
    }
  }

  /// Sync single meal to Firestore
  Future<void> _syncMealToCloud(Meal meal) async {
    final user = _authClient.currentUser;
    if (user == null) return;
    final path = 'users/${user.uid}/meals/${meal.id}';
    final payload = _cloudPayload(meal);

    try {
      await _firestoreClient
          .doc(path)
          .set(payload)
          .timeout(TimeoutPolicy.firestore);
    } catch (e) {
      debugPrint('Meal Sync Error: $e');
      await SyncQueueService().enqueueSet(
        id: 'meal:set:${user.uid}:${meal.id}',
        documentPath: path,
        data: payload,
      );
    }
  }

  Map<String, dynamic> _cloudPayload(Meal meal) {
    // `updatedAt` is when the record was last WRITTEN; `timestamp` is when the
    // meal was eaten. Editing a meal from last Tuesday leaves its timestamp in
    // the past, so only an edit time can drive an incremental pull.
    //
    // It lives in the Firestore document only, not on the Meal model, so no
    // Hive adapter has to be regenerated for this.
    return {
      ...meal.toJson(),
      // Captured meal photos stay on this phone. Uploading the device's local
      // file path would not make the image available elsewhere and would leak
      // a useless path into Firestore. Remote URLs remain syncable.
      'imageUri':
          meal.imageUri?.startsWith('http') == true ? meal.imageUri : null,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
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

    // The meal document is hard-deleted, which older app versions rely on,
    // so a deletion leaves nothing for the user's other devices to read.
    // This tombstone is what tells them the meal is gone.
    final tombstonePath = 'users/${user.uid}/deletedMeals/$id';
    final tombstone = {
      'id': id,
      'deleted': true,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      await _firestoreClient
          .doc(tombstonePath)
          .set(tombstone)
          .timeout(TimeoutPolicy.firestore);
    } catch (e) {
      debugPrint('Meal tombstone queued: $e');
      await SyncQueueService().enqueueSet(
        id: 'meal:tombstone:${user.uid}:$id',
        documentPath: tombstonePath,
        data: tombstone,
        merge: false,
      );
    }
  }

  /// How far back a first-ever sync on a device reaches.
  static const _initialSyncWindow = Duration(days: 30);

  /// Overlap subtracted from the stored cursor, to tolerate clock differences
  /// between two devices belonging to the same user. Re-reading a couple of
  /// minutes of documents is far cheaper than silently missing one.
  static const _cursorOverlap = Duration(minutes: 5);

  static const _cursorKeyPrefix = 'mealSyncCursor:';

  String _cursorKey(String uid) => '$_cursorKeyPrefix$uid';

  /// Pull meals changed since the last sync.
  ///
  /// This used to re-download every meal from the last 30 days on every single
  /// launch — roughly 90 documents per app open, for data the device already
  /// had. Firestore bills per document read, so at 250k daily actives opening
  /// the app three times a day that is on the order of 60 million reads a day
  /// to learn nothing, and it was comfortably the largest read source in the
  /// system.
  ///
  /// Now the device remembers when it last synced and asks only for documents
  /// written since. A steady-state launch reads zero to a couple of documents.
  ///
  /// The first sync on a device has no cursor and still takes the 30-day
  /// window: meals written by older app versions carry no `updatedAt`, and
  /// Firestore excludes documents missing a field from a range filter, so an
  /// incremental query would never see them. That full pull happens once per
  /// device, and everything after it is incremental.
  Future<void> syncFromFirestore() =>
      _pullInFlight ??= _pull().whenComplete(() => _pullInFlight = null);

  Future<void>? _pullInFlight;

  Future<void> _pull() async {
    final user = _authClient.currentUser;
    if (user == null) return;
    await SyncQueueService().init();

    try {
      final cursor = _indexBox?.get(_cursorKey(user.uid));
      final lastSyncMs =
          cursor != null && cursor.isNotEmpty
              ? int.tryParse(cursor.first)
              : null;

      final collection = _firestoreClient
          .collection('users')
          .doc(user.uid)
          .collection('meals');

      final query =
          lastSyncMs == null
              ? collection.where(
                'timestamp',
                isGreaterThanOrEqualTo:
                    DateTime.now()
                        .subtract(_initialSyncWindow)
                        .millisecondsSinceEpoch,
              )
              : collection.where(
                'updatedAt',
                isGreaterThan: lastSyncMs - _cursorOverlap.inMilliseconds,
              );

      final snapshot = await query.get().timeout(TimeoutPolicy.firestore);

      debugPrint(
        lastSyncMs == null
            ? 'MealRepository: first sync on this device, ${snapshot.docs.length} docs'
            : 'MealRepository: incremental sync, ${snapshot.docs.length} docs',
      );

      // Deletions first, so a meal deleted and then restored between two
      // pulls ends up present. A first pull has nothing to delete.
      if (lastSyncMs != null) await _applyDeletedMeals(user.uid, lastSyncMs);

      for (var doc in snapshot.docs) {
        final cloudMeal = Meal.fromJson(doc.data());
        if (_mealsBox == null) continue;

        // A change on this phone the cloud has not received yet is newer than
        // anything the cloud can say about this meal.
        if (SyncQueueService().hasPendingFor(doc.reference.path)) continue;

        // The cloud copy wins otherwise. This compared `timestamp` -- when the
        // meal was eaten -- which an edit does not change, so a meal edited on
        // one phone never updated on another. Every write here is either
        // uploaded straight away or queued, so the cloud is the newer copy.
        //
        // Photos are never uploaded, so a cloud copy has no local image path;
        // keep this phone's photo rather than blanking it.
        final local = _mealsBox!.get(cloudMeal.id);
        final keepPhoto = cloudMeal.imageUri == null && local?.imageUri != null;
        await _saveMealLocalOnly(
          keepPhoto ? cloudMeal.copyWith(imageUri: local!.imageUri) : cloudMeal,
        );
      }

      // Advance the cursor only after the whole page has been applied, and
      // never on a first sync that came back empty.
      //
      // An empty first sync is indistinguishable from a failed one. Firestore
      // returns zero documents both when the user genuinely has no meals and
      // when a read was refused or raced the auth token settling on sign-in —
      // and the permission-denied case does not always throw. Writing the
      // cursor there marks the device permanently "already synced", so the
      // one-time 30-day pull never runs again and the user's history stays
      // empty forever with no error anywhere.
      //
      // Holding the cursor back costs one empty query per launch until the
      // account has its first meal, which is a single document read. That is
      // an unmeasurable price for removing a silent, permanent data-loss mode.
      final worthRecording = lastSyncMs != null || snapshot.docs.isNotEmpty;
      if (worthRecording) {
        await _indexBox?.put(_cursorKey(user.uid), [
          DateTime.now().millisecondsSinceEpoch.toString(),
        ]);
      } else {
        debugPrint(
          'MealRepository: first sync found nothing, not recording a cursor '
          '— the full pull will be retried next launch.',
        );
      }

      _emitTodaysMeals();
    } catch (e) {
      // The cursor is deliberately NOT advanced here: a failed sync must retry
      // the same range next launch rather than stepping over it.
      debugPrint('Meal Pull Error: $e');
    }
  }

  /// Removes meals the user deleted on another device since the last pull.
  ///
  /// A failure here must not stop the meals themselves from syncing, so it is
  /// logged and skipped; that also keeps an app released ahead of the rules
  /// for this collection from losing meal sync altogether.
  Future<void> _applyDeletedMeals(String uid, int lastSyncMs) async {
    try {
      final tombstones = await _firestoreClient
          .collection('users')
          .doc(uid)
          .collection('deletedMeals')
          .where(
            'updatedAt',
            isGreaterThan: lastSyncMs - _cursorOverlap.inMilliseconds,
          )
          .get()
          .timeout(TimeoutPolicy.firestore);
      for (final doc in tombstones.docs) {
        if (_mealsBox?.containsKey(doc.id) != true) continue;
        if (SyncQueueService().hasPendingFor('users/$uid/meals/${doc.id}')) {
          continue;
        }
        final meal = await _deleteMealLocalOnly(doc.id);
        await _deleteUnusedLocalImage(meal?.imageUri);
      }
    } catch (e) {
      debugPrint('Deleted-meal pull skipped: $e');
    }
  }

  /// Uploads every meal on this phone to the signed-in account, in batches:
  /// how a guest's meals reach an account they have just signed in to.
  Future<void> pushAllLocal() async {
    final user = _authClient.currentUser;
    final box = _mealsBox;
    if (user == null || box == null || box.isEmpty) return;
    final meals = box.values.toList();
    const batchLimit = 400;
    for (var i = 0; i < meals.length; i += batchLimit) {
      final end = i + batchLimit < meals.length ? i + batchLimit : meals.length;
      final chunk = meals.sublist(i, end);
      final batch = _firestoreClient.batch();
      for (final meal in chunk) {
        batch.set(
          _firestoreClient.doc('users/${user.uid}/meals/${meal.id}'),
          _cloudPayload(meal),
        );
      }
      try {
        await batch.commit().timeout(TimeoutPolicy.firestore);
      } catch (e) {
        debugPrint('Meal upload queued: $e');
        for (final meal in chunk) {
          await SyncQueueService().enqueueSet(
            id: 'meal:set:${user.uid}:${meal.id}',
            documentPath: 'users/${user.uid}/meals/${meal.id}',
            data: _cloudPayload(meal),
          );
        }
      }
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
    // Clearing the index box also drops the sync cursor, which is what we
    // want: an empty device must take the full 30-day pull again rather than
    // asking for changes since a time when it still had the data.
    await _mealsBox?.clear();
    await _indexBox?.clear();
    _emitTodaysMeals();
  }

  void dispose() {
    _authSubscription?.cancel();
    _mealsController.close();
  }
}
