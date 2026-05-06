import 'package:flutter/material.dart';
import '../data/services/health_service.dart';

class ActivityProvider with ChangeNotifier {
  final HealthService _healthService = HealthService();
  
  HealthData _data = HealthData.empty();
  bool _isAuthorized = false;
  bool _isLoading = false;

  HealthData get data => _data;
  bool get isAuthorized => _isAuthorized;
  bool get isLoading => _isLoading;

  int get burnedCalories => _data.burnedCalories;
  int get steps => _data.steps;

  ActivityProvider() {
    // We don't auto-authorize on init to respect user privacy
    // But we can check if we already have access
  }

  Future<void> authorize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAuthorized = await _healthService.authorize();
      if (_isAuthorized) {
        await syncData();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncData() async {
    if (!_isAuthorized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _data = await _healthService.fetchTodaysData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
