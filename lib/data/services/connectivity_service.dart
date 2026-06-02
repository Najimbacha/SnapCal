import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_queue_service.dart';
import 'upload_queue_service.dart';

/// Enhanced Connectivity Service using connectivity_plus for stable network tracking.
class ConnectivityService with ChangeNotifier {
  bool _isOnline = true;
  bool _hasInternetAccess = true;
  DateTime? _lastReachabilityCheck;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  ConnectivityService() {
    _checkInitialStatus();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  bool get isOnline => _isOnline;
  bool get hasInternetAccess => _isOnline && _hasInternetAccess;

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

    if (online) {
      unawaited(refreshReachability());
    } else if (_hasInternetAccess) {
      _hasInternetAccess = false;
      notifyListeners();
    }
  }

  Future<bool> refreshReachability({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastReachabilityCheck != null &&
        now.difference(_lastReachabilityCheck!) < const Duration(seconds: 20)) {
      return hasInternetAccess;
    }

    _lastReachabilityCheck = now;
    var reachable = false;
    if (_isOnline) {
      try {
        final addresses = await InternetAddress.lookup(
          'example.com',
        ).timeout(const Duration(seconds: 2));
        reachable =
            addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty;
      } catch (e) {
        debugPrint('⚠️ Connectivity reachability check failed: $e');
      }
    }

    if (reachable != _hasInternetAccess) {
      _hasInternetAccess = reachable;
      notifyListeners();
    }
    if (reachable) {
      unawaited(SyncQueueService().flushDue());
      unawaited(UploadQueueService().flushDue());
    }
    return hasInternetAccess;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
