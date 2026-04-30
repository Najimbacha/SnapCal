import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/grocery_item.dart';
import '../data/models/meal.dart';
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
  bool _isRegenerating = false;
  bool get isRegenerating => _isRegenerating;
  String? _error;
  String? get error => _error;
  int _regenCountThisWeek = 0;
  int get regenCountThisWeek => _regenCountThisWeek;

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
    _error = null;
    notifyListeners();

    try {
      final userSettings = _settingsProvider.settings;
      final result = await _aiService.generateWeeklyMealPlan(userSettings);

      if (result != null) {
        _currentPlan = result.plan;
        await _planBox?.put('current', _currentPlan!);

        await _groceryBox?.clear();
        await _groceryBox?.addAll(result.groceryList);
        _groceryList = result.groceryList;
        _regenCountThisWeek = 0;
      } else {
        _error = 'Failed to generate plan. Please try again.';
      }
    } catch (e) {
      debugPrint('Error generating plan: $e');
      _error = 'Something went wrong. Please try again.';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Regenerate a single day's meals (premium, 3/week for free)
  Future<void> regenerateDay(int dayIndex) async {
    if (_currentPlan == null) return;

    _isRegenerating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _aiService.regenerateDay(
        _settingsProvider.settings,
        dayIndex,
        _currentPlan!.weeklyMeals,
      );

      if (result != null && result.plan.weeklyMeals.containsKey(dayIndex)) {
        final updatedMeals = Map<int, List<Meal>>.from(_currentPlan!.weeklyMeals);
        updatedMeals[dayIndex] = result.plan.weeklyMeals[dayIndex]!;
        _currentPlan = _currentPlan!.copyWith(weeklyMeals: updatedMeals);
        await _planBox?.put('current', _currentPlan!);

        // Merge new grocery items without duplicates
        final existingNames = _groceryList.map((g) => g.name.toLowerCase()).toSet();
        for (final newItem in result.groceryList) {
          if (!existingNames.contains(newItem.name.toLowerCase())) {
            _groceryList.add(newItem);
            await _groceryBox?.add(newItem);
          }
        }

        _regenCountThisWeek++;
      } else {
        _error = 'Failed to regenerate. Please try again.';
      }
    } catch (e) {
      debugPrint('Error regenerating day: $e');
      _error = 'Something went wrong. Please try again.';
    } finally {
      _isRegenerating = false;
      notifyListeners();
    }
  }

  bool get canRegenerate {
    if (_settingsProvider.isPro) return true;
    return _regenCountThisWeek < 3;
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Format grocery list for sharing
  String getFormattedGroceryList() {
    if (_groceryList.isEmpty) return '';

    final grouped = <String, List<String>>{};
    for (final item in _groceryList) {
      final cat = item.category.isNotEmpty ? item.category : 'Other';
      grouped.putIfAbsent(cat, () => []).add(
        item.amount.isNotEmpty ? '${item.name} — ${item.amount}' : item.name,
      );
    }

    final categoryEmojis = {
      'produce': '🥬', 'grains': '🌾', 'protein': '🥩', 'meat': '🥩',
      'dairy': '🧀', 'fruits': '🍎', 'vegetables': '🥬', 'snacks': '🍿',
      'beverages': '🥤', 'condiments': '🧂', 'oils': '🫒', 'other': '📦',
      'frozen': '🧊', 'bakery': '🍞', 'seafood': '🐟', 'spices': '🌶️',
    };

    final buffer = StringBuffer('🛒 SnapCal Grocery List\n');
    grouped.forEach((category, items) {
      final emoji = categoryEmojis[category.toLowerCase()] ?? '📦';
      buffer.writeln('\n$emoji ${category.toUpperCase()}');
      for (final item in items) {
        buffer.writeln('  • $item');
      }
    });

    return buffer.toString();
  }

  /// Clear all planner data (logout)
  Future<void> clear() async {
    await _planBox?.clear();
    await _groceryBox?.clear();
    _currentPlan = null;
    _groceryList = [];
    _regenCountThisWeek = 0;
    _error = null;
    notifyListeners();
  }
}

