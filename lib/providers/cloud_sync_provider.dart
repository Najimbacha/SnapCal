import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/app_lifecycle_service.dart';
import '../data/services/cloud_record_sync.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/sync_queue_service.dart';
import 'auth_state_provider.dart';
import 'metrics_provider.dart';
import 'repository_providers.dart';
import 'template_provider.dart';
import 'water_provider.dart';

enum CloudSyncPhase { idle, syncing, failed }

@immutable
class CloudSyncState {
  const CloudSyncState({this.phase = CloudSyncPhase.idle, this.lastSyncedAt});

  final CloudSyncPhase phase;
  final DateTime? lastSyncedAt;

  bool get isSyncing => phase == CloudSyncPhase.syncing;
}

/// Keeps what the user logs in step with their account: first sends changes
/// waiting in the queue, then pulls what changed on their other devices.
///
/// Runs on sign-in, when the app returns to the foreground (at most every few
/// minutes), when the connection comes back, and from "Sync now" in Data &
/// Sync. Meals and settings also pull on their own at sign-in; asking again is
/// cheap, because every pull is incremental and a second request joins the
/// one already running.
final cloudSyncProvider = NotifierProvider<CloudSyncNotifier, CloudSyncState>(
  CloudSyncNotifier.new,
);

class CloudSyncNotifier extends Notifier<CloudSyncState> {
  static const _foregroundInterval = Duration(minutes: 5);
  static const _stepTimeout = Duration(seconds: 30);
  static const _lastSyncKey = 'lastSync';

  Future<bool>? _inFlight;
  DateTime? _lastAttempt;
  bool _wasOnline = false;

  @override
  CloudSyncState build() {
    ref.listen(authStateProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user == null || user.uid == previous?.valueOrNull?.uid) return;
      // A different account: nothing about the last one's sync applies.
      state = const CloudSyncState();
      _lastAttempt = null;
      unawaited(_loadLastSynced(user.uid));
      unawaited(syncNow());
    }, fireImmediately: true);

    final lifecycle = AppLifecycleService();
    final connectivity = ConnectivityService();
    _wasOnline = connectivity.hasInternetAccess;
    void onLifecycle() {
      if (lifecycle.isResumed) _syncIfStale();
    }

    void onConnectivity() {
      final online = connectivity.hasInternetAccess;
      if (online && !_wasOnline) unawaited(syncNow());
      _wasOnline = online;
    }

    lifecycle.addListener(onLifecycle);
    connectivity.addListener(onConnectivity);
    ref.onDispose(() {
      lifecycle.removeListener(onLifecycle);
      connectivity.removeListener(onConnectivity);
    });
    return const CloudSyncState();
  }

  void _syncIfStale() {
    final last = _lastAttempt;
    if (last != null && DateTime.now().difference(last) < _foregroundInterval) {
      return;
    }
    unawaited(syncNow());
  }

  Future<void> _loadLastSynced(String uid) async {
    try {
      final ms = await SyncCursorStore.get(uid, _lastSyncKey);
      if (ms == null || FirebaseAuth.instance.currentUser?.uid != uid) return;
      if (state.lastSyncedAt != null) return;
      state = CloudSyncState(
        phase: state.phase,
        lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(ms),
      );
    } catch (e) {
      debugPrint('Cloud sync: last-synced time unavailable: $e');
    }
  }

  /// Sends waiting changes, then pulls everything that changed elsewhere.
  /// Returns whether every step completed. Concurrent calls share one run.
  ///
  /// [manual] is set by "Sync now", which also re-reads settings that are
  /// otherwise refreshed at most every few hours.
  Future<bool> syncNow({bool manual = false}) =>
      _inFlight ??= _run(manual).whenComplete(() => _inFlight = null);

  Future<bool> _run(bool manual) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    _lastAttempt = DateTime.now();
    state = CloudSyncState(
      phase: CloudSyncPhase.syncing,
      lastSyncedAt: state.lastSyncedAt,
    );

    var ok = true;
    Future<void> step(String name, Future<void> Function() task) async {
      try {
        await task().timeout(_stepTimeout);
      } catch (e) {
        ok = false;
        debugPrint('Cloud sync: $name failed: $e');
      }
    }

    await step('queue', () => SyncQueueService().flushDue());
    await step('meals', () async {
      final repo = await ref.read(mealRepositoryProvider.future);
      await repo.syncFromFirestore();
    });
    await step('settings', () async {
      final repo = await ref.read(settingsRepositoryProvider.future);
      await repo.syncFromFirestore(force: manual);
    });
    await step('water', () async {
      final repo = await ref.read(waterRepositoryProvider.future);
      if (await repo.pullFromCloud()) ref.invalidate(waterProvider);
    });
    await step('weight', () async {
      await ref.read(bodyMetricsProvider.notifier).pullFromCloud();
    });
    await step('templates', () async {
      await ref.read(templatesProvider.notifier).pullFromCloud();
    });

    // Signed out or switched accounts part-way through: this run's result
    // belongs to neither account.
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
      state = const CloudSyncState();
      return false;
    }

    final now = DateTime.now();
    if (ok) {
      await SyncCursorStore.set(
        user.uid,
        _lastSyncKey,
        now.millisecondsSinceEpoch,
      );
    }
    state = CloudSyncState(
      phase: ok ? CloudSyncPhase.idle : CloudSyncPhase.failed,
      lastSyncedAt: ok ? now : state.lastSyncedAt,
    );
    return ok;
  }

  /// Carries everything on this phone into the signed-in account.
  ///
  /// For a guest who signs in to an account that already exists: signing in
  /// moves them to that account's identity, and what they logged as a guest
  /// is on this phone only. Without this it stayed visible here but was never
  /// backed up, and was gone on a reinstall or a new phone.
  Future<void> uploadAllLocal() async {
    Future<void> step(String name, Future<void> Function() task) async {
      try {
        await task().timeout(const Duration(minutes: 2));
      } catch (e) {
        debugPrint('Cloud sync: uploading local $name failed: $e');
      }
    }

    await step('meals', () async {
      final repo = await ref.read(mealRepositoryProvider.future);
      await repo.pushAllLocal();
    });
    await step('water', () async {
      final repo = await ref.read(waterRepositoryProvider.future);
      await repo.pushAllLocal();
    });
    await step('weight', () async {
      await ref.read(bodyMetricsProvider.notifier).pushAllLocal();
    });
    await step('templates', () async {
      await ref.read(templatesProvider.notifier).pushAllLocal();
    });
  }
}
