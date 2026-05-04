import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Enhanced Connectivity Service using connectivity_plus for stable network tracking.
class ConnectivityService with ChangeNotifier {
  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityService() {
    _checkInitialStatus();
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  bool get isOnline => _isOnline;

  Future<void> _checkInitialStatus() async {
    final result = await _connectivity.checkConnectivity();
    _onConnectivityChanged(result);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // connectivity_plus 6.0+ returns a List of results (e.g. WiFi + VPN)
    final online = results.any((r) => r != ConnectivityResult.none);
    
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
