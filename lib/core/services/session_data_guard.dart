import 'dart:async';

/// Serializes cloud-to-local writes with session cleanup. A UID check alone
/// cannot detect logout and login to the same account while a request is pending.
class SessionDataGuard {
  static final instance = SessionDataGuard();
  int _generation = 0;
  int _cleanups = 0;
  Future<void> _tail = Future<void>.value();

  int get generation => _generation;

  SessionLease capture(String? Function() currentUid) =>
      SessionLease._(this, _generation, currentUid(), currentUid);

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<T> cleanup<T>(Future<T> Function() action) {
    _generation++;
    _cleanups++;
    return _serialized(action).whenComplete(() {
      _generation++;
      _cleanups--;
    });
  }
}

class StaleSessionException implements Exception {
  const StaleSessionException();
  @override
  String toString() => 'The account changed while the operation was running.';
}

class SessionLease {
  SessionLease._(this._guard, this.generation, this.uid, this._currentUid);
  final SessionDataGuard _guard;
  final int generation;
  final String? uid;
  final String? Function() _currentUid;
  bool get isCurrent =>
      _guard._cleanups == 0 &&
      generation == _guard.generation &&
      uid == _currentUid();

  void check() {
    if (!isCurrent) throw const StaleSessionException();
  }

  Future<T> write<T>(Future<T> Function() action) => _guard._serialized(() {
    check();
    return action();
  });
}
