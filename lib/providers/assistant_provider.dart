import 'package:flutter/foundation.dart';
import '../data/repositories/assistant_repository.dart';
import '../data/services/assistant_service.dart';

class AssistantProvider with ChangeNotifier {
  final AssistantRepository _repository;
  final AssistantService _service = AssistantService();

  AssistantProvider(this._repository) {
    _loadHistory();
  }

  void _loadHistory() {
    final history = _repository.getChatHistory();
    if (history != null) {
      _history = history;
      notifyListeners();
    }
  }

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
    List<String> mealNames = const [],
    String dietaryRestriction = 'none',
    String? userQuery,
    Uint8List? imageBytes, // New: Image support
    bool clearPrevious = false,
    bool forceFetch = false,
  }) async {
    if (clearPrevious) {
      _history = [];
      notifyListeners();
      await _repository.saveChatHistory(_history);
    }

    // Add user query to history immediately if it exists
    if (userQuery != null) {
      _history.add({'type': 'user', 'content': userQuery, 'hasImage': imageBytes != null});
      notifyListeners();
      await _repository.saveChatHistory(_history);
    }

    // Check Cache for "Initial" requests (only if no specific query and NOT forcing fetch)
    if (userQuery == null && imageBytes == null && !forceFetch) {
      final cached = _repository.getCachedRecommendations();
      final lastCals = _repository.getLastCalorieSnapshot();
      final calDiff = (currentCalories - lastCals).abs();

      if (cached != null && calDiff < 50 && _history.isEmpty) {
        _history = List<dynamic>.from(cached);
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<AssistantResponse> newRecs;
      
      if (imageBytes != null) {
        // New: Handle Image Analysis
        newRecs = await _service.analyzeImage(
          imageBytes: imageBytes,
          userQuery: userQuery,
          currentCalories: currentCalories,
          targetCalories: targetCalories,
        );
      } else {
        newRecs = await _service.getRecommendations(
          currentCalories: currentCalories,
          targetCalories: targetCalories,
          currentMacros: currentMacros,
          targetMacros: targetMacros,
          mealNames: mealNames,
          dietaryRestriction: dietaryRestriction,
          userQuery: userQuery,
        );
      }

      if (userQuery != null || imageBytes != null) {
        // For queries/images, append to history
        _history.addAll(newRecs);
      } else {
        // For fresh general recommendations, replace
        _history = List<dynamic>.from(newRecs);
      }

      // Save to cache/history
      await _repository.saveChatHistory(_history);
      if (userQuery == null && imageBytes == null) {
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

  /// Clear all assistant data (logout)
  Future<void> clear() async {
    await _repository.clearCache();
    _history = [];
    _error = null;
    notifyListeners();
  }
}
