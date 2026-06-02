import 'package:flutter/widgets.dart';

class AppLifecycleService with WidgetsBindingObserver, ChangeNotifier {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  bool _initialized = false;
  AppLifecycleState _state = AppLifecycleState.resumed;
  int _memoryPressureCount = 0;

  AppLifecycleState get state => _state;
  bool get isResumed => _state == AppLifecycleState.resumed;
  bool get isPaused =>
      _state == AppLifecycleState.paused ||
      _state == AppLifecycleState.inactive ||
      _state == AppLifecycleState.detached;
  int get memoryPressureCount => _memoryPressureCount;

  void init() {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_state == state) return;
    _state = state;
    notifyListeners();
  }

  @override
  void didHaveMemoryPressure() {
    _memoryPressureCount++;
    notifyListeners();
  }
}
