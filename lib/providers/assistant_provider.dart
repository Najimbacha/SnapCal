import 'package:flutter/foundation.dart';
import '../data/repositories/assistant_repository.dart';
import '../data/services/assistant_service.dart';

class AssistantProvider with ChangeNotifier {
  final AssistantRepository _repository;
  final AssistantService _service = AssistantService();

  AssistantProvider(this._repository);

  AssistantService get service => _service;

  List<dynamic> _history = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch recommendations based on user stats (with caching)
  Future<void> fetchRecommendations({
    required int currentCalories,
    required int targetCalories,
    required Map<String, int> currentMacros,
    required Map<String, int> targetMacros,
    String? userQuery,
    bool clearPrevious = false,
  }) async {
    if (clearPrevious) {
      _history = [];
      notifyListeners();
    }

    // Add user query to history immediately if it exists
    if (userQuery != null) {
      _history.add({'type': 'user', 'content': userQuery});
      notifyListeners();
    }

    // Check Cache for "Initial" requests (only if no specific query)
    if (userQuery == null) {
      final cached = _repository.getCachedRecommendations();
      final lastCals = _repository.getLastCalorieSnapshot();
      final calDiff = (currentCalories - lastCals).abs();

      if (cached != null && calDiff < 50) {
        _history = List<dynamic>.from(cached);
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newRecs = await _service.getRecommendations(
        currentCalories: currentCalories,
        targetCalories: targetCalories,
        currentMacros: currentMacros,
        targetMacros: targetMacros,
        userQuery: userQuery,
      );

      if (userQuery != null) {
        // For queries, append to history
        _history.addAll(newRecs);
      } else {
        // For fresh general recommendations, replace
        _history = List<dynamic>.from(newRecs);
      }

      // Save to cache if it's a general recommendation
      if (userQuery == null) {
        await _repository.saveRecommendations(newRecs);
        await _repository.saveCalorieSnapshot(currentCalories);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
