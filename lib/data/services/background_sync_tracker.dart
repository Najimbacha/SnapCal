import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tracks local-first cloud writes that have not reached the durable retry
/// queue yet. Destructive session transitions wait here before inspecting the
/// queue, closing the short race between a local save and its network timeout.
class BackgroundSyncTracker {
  static final BackgroundSyncTracker _instance =
      BackgroundSyncTracker._internal();
  factory BackgroundSyncTracker() => _instance;
  BackgroundSyncTracker._internal();

  final Set<Future<void>> _pending = {};
  Object? _failure;
  int _generation = 0;

  int get pendingCount => _pending.length;

  void track(Future<void> write) {
    final generation = _generation;
    late final Future<void> settled;
    settled = write.then<void>(
      (_) {
        if (generation == _generation) _pending.remove(settled);
      },
      onError: (Object error, StackTrace stack) {
        if (generation != _generation) return;
        _failure ??= error;
        _pending.remove(settled);
      },
    );
    _pending.add(settled);
  }

  Future<void> waitForIdle() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.toList());
    }
    final failure = _failure;
    if (failure != null) throw BackgroundSyncFailure(failure);
  }

  /// Forgets operations owned by a session after its local stores have been
  /// cleared. Generation checks keep their late completions out of the next
  /// account's tracker state.
  void discardSessionState() {
    _generation++;
    _pending.clear();
    _failure = null;
  }

  @visibleForTesting
  void resetForTesting() => discardSessionState();
}

class BackgroundSyncFailure implements Exception {
  const BackgroundSyncFailure(this.cause);

  final Object cause;

  @override
  String toString() => 'A background sync write could not be queued: $cause';
}
