import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/grocery_item.dart';
import '../data/models/meal.dart';
import '../data/models/meal_plan.dart';
import '../data/services/gemini_service.dart';
import '../core/state/async_ui_state.dart';
import 'settings_provider.dart';
import '../l10n/generated/app_localizations.dart';

class PlannerProvider with ChangeNotifier {
  static const String _planBoxName = 'meal_plan_box';
  static const String _groceryBoxName = 'grocery_list_box';

  final AIService _aiService;
  SettingsProvider _settingsProvider;

  Box<MealPlan>? _planBox;
  Box<GroceryItem>? _groceryBox;

  MealPlan? _currentPlan;
  List<GroceryItem> _groceryList = [];

  AsyncUiState _uiState = const AsyncUiState.loading();
  bool get isLoading => _uiState.isBlocking;
  bool get isRefreshing => _uiState.isRefreshing;
  AsyncUiState get uiState => _uiState;
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;
  bool _isRegenerating = false;
  bool get isRegenerating => _isRegenerating;
  String? _error;
  String? get error => _error;
  int _regenCountThisWeek = 0;
  int get regenCountThisWeek => _regenCountThisWeek;
  AppLocalizations get _l10n =>
      lookupAppLocalizations(Locale(_settingsProvider.languageCode));

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
    try {
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
      _uiState =
          _currentPlan == null
              ? const AsyncUiState.empty()
              : const AsyncUiState.success();
    } catch (e) {
      debugPrint('⚠️ PlannerProvider: failed to initialize: $e');
      _error = _l10n.error_generic;
      _uiState = AsyncUiState.error(_error);
    } finally {
      notifyListeners();
    }
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
    if (_isGenerating) return;
    _isGenerating = true;
    _uiState =
        _currentPlan == null
            ? const AsyncUiState.loading()
            : const AsyncUiState.refreshing();
    _error = null;
    notifyListeners();

    try {
      final userSettings = _settingsProvider.settings;
      final result = await _aiService
          .generateWeeklyMealPlan(userSettings)
          .timeout(const Duration(seconds: 20));

      if (result != null) {
        _currentPlan = result.plan;
        await _planBox?.put('current', _currentPlan!);

        await _groceryBox?.clear();
        await _groceryBox?.addAll(result.groceryList);
        _groceryList = result.groceryList;
        _regenCountThisWeek = 0;
      } else {
        _error = _l10n.error_generic;
      }
    } catch (e) {
      debugPrint('Error generating plan: $e');
      _error = _l10n.error_generic;
    } finally {
      _isGenerating = false;
      _uiState =
          _currentPlan == null
              ? (_error == null
                  ? const AsyncUiState.empty()
                  : AsyncUiState.error(_error))
              : const AsyncUiState.success();
      notifyListeners();
    }
  }

  /// Regenerate a single day's meals (Pro only).
  Future<void> regenerateDay(int dayIndex) async {
    if (_currentPlan == null) return;

    if (_isRegenerating) return;
    _isRegenerating = true;
    _uiState = const AsyncUiState.refreshing();
    _error = null;
    notifyListeners();

    try {
      final result = await _aiService
          .regenerateDay(
            _settingsProvider.settings,
            dayIndex,
            _currentPlan!.weeklyMeals,
          )
          .timeout(const Duration(seconds: 18));

      if (result != null && result.plan.weeklyMeals.containsKey(dayIndex)) {
        final updatedMeals = Map<int, List<Meal>>.from(
          _currentPlan!.weeklyMeals,
        );
        updatedMeals[dayIndex] = result.plan.weeklyMeals[dayIndex]!;
        _currentPlan = _currentPlan!.copyWith(weeklyMeals: updatedMeals);
        await _planBox?.put('current', _currentPlan!);

        // Merge new grocery items without duplicates
        final existingNames =
            _groceryList.map((g) => g.name.toLowerCase()).toSet();
        for (final newItem in result.groceryList) {
          if (!existingNames.contains(newItem.name.toLowerCase())) {
            _groceryList.add(newItem);
            await _groceryBox?.add(newItem);
          }
        }

        _regenCountThisWeek++;
      } else {
        _error = _l10n.error_generic;
      }
    } catch (e) {
      debugPrint('Error regenerating day: $e');
      _error = _l10n.error_generic;
    } finally {
      _isRegenerating = false;
      _uiState = const AsyncUiState.success();
      notifyListeners();
    }
  }

  bool get canRegenerate {
    return _settingsProvider.isPro;
  }

  Future<void> toggleGroceryItem(String id) async {
    try {
      final index = _groceryList.indexWhere((i) => i.id == id);
      if (index != -1) {
        final item = _groceryList[index];
        item.isChecked = !item.isChecked;
        await item.save();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling grocery item: $e');
    }
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
      grouped
          .putIfAbsent(cat, () => [])
          .add(
            item.amount.isNotEmpty
                ? '${item.name} — ${item.amount}'
                : item.name,
          );
    }

    final categoryEmojis = {
      'produce': '🥬',
      'grains': '🌾',
      'protein': '🥩',
      'meat': '🥩',
      'dairy': '🧀',
      'fruits': '🍎',
      'vegetables': '🥬',
      'snacks': '🍿',
      'beverages': '🥤',
      'condiments': '🧂',
      'oils': '🫒',
      'other': '📦',
      'frozen': '🧊',
      'bakery': '🍞',
      'seafood': '🐟',
      'spices': '🌶️',
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
