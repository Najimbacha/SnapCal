import 'package:flutter/foundation.dart';
import '../data/services/assistant_service.dart';

class AssistantProvider with ChangeNotifier {
  final AssistantService _service = AssistantService();

  List<AssistantResponse> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  List<AssistantResponse> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch recommendations based on user stats
  Future<void> fetchRecommendations({
    required int currentCalories,
    required int targetCalories,
    required Map<String, int> currentMacros,
    required Map<String, int> targetMacros,
    String? userQuery,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recommendations = await _service.getRecommendations(
        currentCalories: currentCalories,
        targetCalories: targetCalories,
        currentMacros: currentMacros,
        targetMacros: targetMacros,
        userQuery: userQuery,
      );
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
