import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/resilience/timeout_policy.dart';
import 'sync_queue_service.dart';

/// Keeps one per-user Firestore collection of small records in step with the
/// phone: `users/{uid}/{collection}/{id}`.
///
/// Every write carries `updatedAt`, so another device can ask for only what
/// changed since it last looked. A delete is written as a tombstone --
/// `{id, deleted: true, updatedAt}` -- instead of removing the document,
/// because a device that was offline can only learn of a deletion it can read.
/// Meals predate this and keep their own scheme; see `MealRepository`.
class CloudRecordSync {
  CloudRecordSync(
    this.collection, {
    this.initialWindow,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore,
       _auth = auth;

  final String collection;

  /// How far back the first pull on a device reaches, by `updatedAt`. Null
  /// takes everything, which suits small collections like weight history.
  final Duration? initialWindow;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authClient => _auth ?? FirebaseAuth.instance;

  /// Re-read a few minutes before the cursor, to tolerate clock differences
  /// between two of the same user's devices.
  static const _cursorOverlap = Duration(minutes: 5);

  /// Firestore allows 500 writes per batch; stay clear of the limit.
  static const _batchLimit = 400;

  static const _bookkeepingFields = ['id', 'deleted', 'updatedAt'];

  String _path(String uid, String id) => 'users/$uid/$collection/$id';

  int _now() => DateTime.now().millisecondsSinceEpoch;

  /// Uploads [data] as record [id], replacing what the cloud had.
  Future<void> push(String id, Map<String, dynamic> data) =>
      _write(id, {...data, 'id': id, 'deleted': false, 'updatedAt': _now()});

  /// Replaces record [id] with a tombstone.
  Future<void> remove(String id) =>
      _write(id, {'id': id, 'deleted': true, 'updatedAt': _now()});

  Future<void> _write(String id, Map<String, dynamic> payload) async {
    final user = _authClient.currentUser;
    if (user == null) return;
    final path = _path(user.uid, id);
    try {
      await _db.doc(path).set(payload).timeout(TimeoutPolicy.firestore);
    } catch (e) {
      debugPrint('CloudRecordSync($collection): write queued: $e');
      await SyncQueueService().enqueueSet(
        id: '$collection:${user.uid}:$id',
        documentPath: path,
        data: payload,
        merge: false,
      );
    }
  }

  /// Uploads every record in [records] in batches. Used to carry data that is
  /// only on this phone into an account -- a guest signing in to one.
  Future<void> pushAll(Map<String, Map<String, dynamic>> records) async {
    final user = _authClient.currentUser;
    if (user == null || records.isEmpty) return;
    final now = _now();
    final entries = records.entries.toList();
    for (var i = 0; i < entries.length; i += _batchLimit) {
      final chunk = entries.sublist(i, min(i + _batchLimit, entries.length));
      final batch = _db.batch();
      final payloads = <String, Map<String, dynamic>>{};
      for (final entry in chunk) {
        final payload = {
          ...entry.value,
          'id': entry.key,
          'deleted': false,
          'updatedAt': now,
        };
        payloads[entry.key] = payload;
        batch.set(_db.doc(_path(user.uid, entry.key)), payload);
      }
      try {
        await batch.commit().timeout(TimeoutPolicy.firestore);
      } catch (e) {
        debugPrint('CloudRecordSync($collection): batch queued: $e');
        for (final entry in payloads.entries) {
          await SyncQueueService().enqueueSet(
            id: '$collection:${user.uid}:${entry.key}',
            documentPath: _path(user.uid, entry.key),
            data: entry.value,
            merge: false,
          );
        }
      }
    }
  }

  /// Applies records changed in the cloud since this device last pulled.
  ///
  /// [upsert] receives a live record's fields, without the bookkeeping ones;
  /// [delete] receives the id of a tombstone. Each returns whether it changed
  /// anything on the phone. Returns whether any record did.
  Future<bool>
  pull({
    required Future<bool> Function(String id, Map<String, dynamic> data) upsert,
    required Future<bool> Function(String id) delete,
  }) =>
      // Sign-in, resume and "Sync now" can all ask at once; one pull serves all.
      _pullInFlight ??= _pull(
        upsert,
        delete,
      ).whenComplete(() => _pullInFlight = null);

  Future<bool>? _pullInFlight;

  Future<bool> _pull(
    Future<bool> Function(String id, Map<String, dynamic> data) upsert,
    Future<bool> Function(String id) delete,
  ) async {
    final user = _authClient.currentUser;
    if (user == null) return false;
    await SyncQueueService().init();

    final cursor = await SyncCursorStore.get(user.uid, collection);
    final records = _db
        .collection('users')
        .doc(user.uid)
        .collection(collection);
    final Query<Map<String, dynamic>> query;
    if (cursor != null) {
      query = records.where(
        'updatedAt',
        isGreaterThan: cursor - _cursorOverlap.inMilliseconds,
      );
    } else if (initialWindow != null) {
      query = records.where(
        'updatedAt',
        isGreaterThanOrEqualTo: _now() - initialWindow!.inMilliseconds,
      );
    } else {
      query = records;
    }

    final startedAt = _now();
    final snapshot = await query.get().timeout(TimeoutPolicy.firestore);
    var changed = false;
    for (final doc in snapshot.docs) {
      // A change this phone has not uploaded yet is newer than anything the
      // cloud can tell it about the record.
      if (SyncQueueService().hasPendingFor(doc.reference.path)) continue;
      final data = doc.data();
      if (data['deleted'] == true) {
        changed = await delete(doc.id) || changed;
      } else {
        final fields = Map<String, dynamic>.of(data)
          ..removeWhere((key, _) => _bookkeepingFields.contains(key));
        changed = await upsert(doc.id, fields) || changed;
      }
    }

    // As in the meal pull, an empty first pull is indistinguishable from one
    // the rules refused, so it does not mark this device as caught up.
    if (cursor != null || snapshot.docs.isNotEmpty) {
      await SyncCursorStore.set(user.uid, collection, startedAt);
    }
    return changed;
  }
}

/// Per-user "last pulled at" times, and the last completed sync.
///
/// A plain Hive box, listed in `SessionCleanupService`, so signing out clears
/// it with everything else: an emptied device must take the full first pull
/// again rather than asking for changes since a time it still had the data.
class SyncCursorStore {
  static const boxName = 'sync_cursor_box';

  static Future<Box<dynamic>> _open() async =>
      Hive.isBoxOpen(boxName)
          ? Hive.box<dynamic>(boxName)
          : await Hive.openBox<dynamic>(boxName);

  static Future<int?> get(String uid, String name) async =>
      (await _open()).get('$uid:$name') as int?;

  static Future<void> set(String uid, String name, int value) async =>
      (await _open()).put('$uid:$name', value);
}
