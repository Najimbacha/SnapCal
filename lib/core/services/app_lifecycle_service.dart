import 'package:flutter/widgets.dart';

class AppLifecycleService with WidgetsBindingObserver, ChangeNotifier {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  bool _initialized = false;
  AppLifecycleState _state = AppLifecycleState.resumed;
  bool _wentAway = false;
  bool _cameBack = false;
  int _memoryPressureCount = 0;

  AppLifecycleState get state => _state;
  bool get isResumed => _state == AppLifecycleState.resumed;
  bool get isPaused =>
      _state == AppLifecycleState.paused ||
      _state == AppLifecycleState.inactive ||
      _state == AppLifecycleState.hidden ||
      _state == AppLifecycleState.detached;

  /// Whether the app has just come back after being out of sight -- home
  /// button, another app, the phone locked. Pulling down the notification
  /// shade or a system dialog only makes it inactive for a moment; that is
  /// not a return, and work that costs a network call or a Health Connect
  /// read should not rerun for it.
  bool get cameBack => isResumed && _cameBack;
  int get memoryPressureCount => _memoryPressureCount;

  void init() {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    _state = WidgetsBinding.instance.lifecycleState ?? _state;
    _initialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state == state) return;
    _state = state;
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _wentAway = true;
    }
    if (state == AppLifecycleState.resumed) {
      _cameBack = _wentAway;
      _wentAway = false;
    }
    notifyListeners();
  }

  /// Counted only. It used to notify listeners too, and every one of them
  /// checks [isResumed] and then works: a phone short of memory -- exactly
  /// when extra work hurts -- re-read Health Connect, re-checked the
  /// subscription and flushed the upload queues each time it said so.
  @override
  void didHaveMemoryPressure() {
    _memoryPressureCount++;
  }
}
