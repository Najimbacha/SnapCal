import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Basic Connectivity Service to track online/offline status.
/// In a production environment, this would use `connectivity_plus`.
class ConnectivityService with ChangeNotifier {
  bool _isOnline = true;
  Timer? _timer;

  ConnectivityService() {
    _checkInitialStatus();
    // Periodically check connection every 30 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  bool get isOnline => _isOnline;

  Future<void> _checkInitialStatus() async {
    await _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
