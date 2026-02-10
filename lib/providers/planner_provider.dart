import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/grocery_item.dart';
import '../data/models/meal_plan.dart';
import '../data/services/gemini_service.dart';
import 'settings_provider.dart';

class PlannerProvider with ChangeNotifier {
  static const String _planBoxName = 'meal_plan_box';
  static const String _groceryBoxName = 'grocery_list_box';

  final AIService _aiService;
  SettingsProvider _settingsProvider;

  Box<MealPlan>? _planBox;
  Box<GroceryItem>? _groceryBox;

  MealPlan? _currentPlan;
  List<GroceryItem> _groceryList = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    notifyListeners();
  }

  MealPlan? get currentPlan => _currentPlan;
  List<GroceryItem> get groceryList => _groceryList;

  PlannerProvider(this._aiService, this._settingsProvider) {
    _init();
  }

  Future<void> _init() async {
    if (!Hive.isBoxOpen(_planBoxName)) {
      _planBox = await Hive.openBox<MealPlan>(_planBoxName);
    } else {
      _planBox = Hive.box<MealPlan>(_planBoxName);
    }

    if (!Hive.isBoxOpen(_groceryBoxName)) {
      _groceryBox = await Hive.openBox<GroceryItem>(_groceryBoxName);
    } else {
      _groceryBox = Hive.box<GroceryItem>(_groceryBoxName);
    }

    _loadData();
    _isLoading = false;
    notifyListeners();
  }

  void _loadData() {
    if (_planBox != null && _planBox!.isNotEmpty) {
      _currentPlan = _planBox!.get('current');
    }

    if (_groceryBox != null) {
      _groceryList = _groceryBox!.values.toList();
    }
  }

  Future<void> generateWeeklyPlan() async {
    _isGenerating = true;
    notifyListeners();

    try {
      final userSettings = _settingsProvider.settings;
      final result = await _aiService.generateWeeklyMealPlan(userSettings);

      if (result != null) {
        // Save Plan
        _currentPlan = result.plan;
        await _planBox?.put('current', _currentPlan!);

        // Save Grocery List
        await _groceryBox?.clear();
        await _groceryBox?.addAll(result.groceryList);
        _groceryList = result.groceryList;
      }
    } catch (e) {
      debugPrint('Error generating plan: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> toggleGroceryItem(String id) async {
    final item = _groceryList.firstWhere((i) => i.id == id);
    item.isChecked = !item.isChecked;
    await item.save();
    notifyListeners();
  }

  Future<void> clearGroceryList() async {
    await _groceryBox?.clear();
    _groceryList = [];
    notifyListeners();
  }
}
