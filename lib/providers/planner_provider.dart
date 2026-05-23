import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/grocery_item.dart';
import '../data/models/meal.dart';
import '../data/models/meal_plan.dart';
import '../data/models/user_settings.dart';
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

  // Shown when AI fails and fallback plan is used instead
  String? _fallbackNotice;
  String? get fallbackNotice => _fallbackNotice;
  void clearFallbackNotice() {
    _fallbackNotice = null;
    notifyListeners();
  }

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

      final planResult = result ?? _buildFallbackPlan(userSettings);
      _currentPlan = planResult.plan;
      await _planBox?.put('current', _currentPlan!);

      await _groceryBox?.clear();
      await _groceryBox?.addAll(planResult.groceryList);
      _groceryList = planResult.groceryList;
      _regenCountThisWeek = 0;
    } catch (e) {
      debugPrint('Error generating plan: $e');
      final planResult = _buildFallbackPlan(_settingsProvider.settings);
      _currentPlan = planResult.plan;
      await _planBox?.put('current', _currentPlan!);

      await _groceryBox?.clear();
      await _groceryBox?.addAll(planResult.groceryList);
      _groceryList = planResult.groceryList;
      _regenCountThisWeek = 0;
      // Surface a soft notice so the UI can optionally inform the user
      _fallbackNotice = _l10n.error_generic;
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

      final planResult =
          result ??
          _buildFallbackPlan(
            _settingsProvider.settings,
            onlyDayIndex: dayIndex,
          );

      if (planResult.plan.weeklyMeals.containsKey(dayIndex)) {
        final updatedMeals = Map<int, List<Meal>>.from(
          _currentPlan!.weeklyMeals,
        );
        updatedMeals[dayIndex] = planResult.plan.weeklyMeals[dayIndex]!;
        _currentPlan = _currentPlan!.copyWith(weeklyMeals: updatedMeals);
        await _planBox?.put('current', _currentPlan!);

        // Remove old grocery items that belong to the regenerated day,
        // then merge new items (deduplicated by name).
        final oldDayFoodNames = _currentPlan!.weeklyMeals[dayIndex]
                ?.map((m) => m.foodName.toLowerCase())
                .toSet() ??
            {};
        _groceryList.removeWhere(
          (g) => oldDayFoodNames.contains(g.name.toLowerCase()),
        );
        await _groceryBox?.clear();
        await _groceryBox?.addAll(_groceryList);

        final existingNames =
            _groceryList.map((g) => g.name.toLowerCase()).toSet();
        for (final newItem in planResult.groceryList) {
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

  PlanGenerationResult _buildFallbackPlan(
    UserSettings settings, {
    int? onlyDayIndex,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final mealsPerDay = (settings.mealsPerDay ?? 3).clamp(2, 5);
    final calorieGoal = settings.dailyCalorieGoal.clamp(900, 5000);
    final proteinGoal = settings.dailyProteinGoal.clamp(20, 350);
    final carbGoal = settings.dailyCarbGoal.clamp(20, 600);
    final fatGoal = settings.dailyFatGoal.clamp(10, 250);
    final dayIndexes =
        onlyDayIndex == null ? List<int>.generate(7, (i) => i) : [onlyDayIndex];
    final weeklyMeals = MealPlan.createEmpty(start: start).weeklyMeals;

    for (final day in dayIndexes) {
      final splits = _mealSplits(mealsPerDay);
      final types = _mealTypes(mealsPerDay);
      weeklyMeals[day] = [
        for (var index = 0; index < mealsPerDay; index++)
          _fallbackMeal(
            settings: settings,
            day: day,
            index: index,
            type: types[index],
            calories: (calorieGoal * splits[index]).round(),
            protein: (proteinGoal * splits[index]).round(),
            carbs: (carbGoal * splits[index]).round(),
            fat: (fatGoal * splits[index]).round(),
            date: start.add(Duration(days: day)),
          ),
      ];
    }

    return PlanGenerationResult(
      plan: MealPlan.createEmpty(start: start).copyWith(weeklyMeals: weeklyMeals),
      groceryList: _fallbackGroceries(settings),
    );
  }

  Meal _fallbackMeal({
    required UserSettings settings,
    required int day,
    required int index,
    required String type,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required DateTime date,
  }) {
    final restriction = settings.dietaryRestriction ?? 'none';
    final cuisine = settings.cuisinePreference ?? 'international';
    final options = _fallbackMealOptions(restriction, cuisine, type);
    final selected = options[(day + index) % options.length];
    final ingredients = selected.$2;
    final timestamp =
        DateTime(date.year, date.month, date.day, 8 + (index * 3), 0)
            .millisecondsSinceEpoch;

    return Meal(
      id: 'planner_${day}_${index}_${date.millisecondsSinceEpoch}',
      timestamp: timestamp,
      dateString: _dateString(date),
      foodName: selected.$1,
      calories: calories,
      macros: Macros(protein: protein, carbs: carbs, fat: fat),
      mealType: type,
      portion: selected.$3,
      prepTimeMins: selected.$4,
      ingredients: ingredients,
      synced: true,
      scanSource: 'planner_fallback',
    );
  }

  List<double> _mealSplits(int mealsPerDay) {
    switch (mealsPerDay) {
      case 2:
        return const [0.44, 0.56];
      case 4:
        return const [0.25, 0.12, 0.35, 0.28];
      case 5:
        return const [0.22, 0.10, 0.30, 0.10, 0.28];
      case 3:
      default:
        return const [0.28, 0.38, 0.34];
    }
  }

  List<String> _mealTypes(int mealsPerDay) {
    switch (mealsPerDay) {
      case 2:
        return const ['Breakfast', 'Dinner'];
      case 4:
        return const ['Breakfast', 'Snack', 'Lunch', 'Dinner'];
      case 5:
        return const ['Breakfast', 'Snack', 'Lunch', 'Snack', 'Dinner'];
      case 3:
      default:
        return const ['Breakfast', 'Lunch', 'Dinner'];
    }
  }

  List<(String, List<String>, String, int)> _fallbackMealOptions(
    String restriction,
    String cuisine,
    String type,
  ) {
    final isVegan = restriction == 'vegan';
    final isVegetarian = restriction == 'vegetarian' || isVegan;
    final isKeto = restriction == 'keto';
    final isMiddleEastern = cuisine == 'middle eastern';
    final isMediterranean = cuisine == 'mediterranean';

    if (type == 'Breakfast') {
      if (isKeto) {
        return const [
          ('Eggs with avocado', ['2 eggs', '1 avocado', 'spinach'], '1 plate', 12),
          ('Greek yogurt bowl', ['Greek yogurt', 'chia seeds', 'walnuts'], '1 bowl', 5),
        ];
      }
      if (isVegan) {
        return const [
          ('Oats with banana and tahini', ['oats', 'banana', 'tahini'], '1 bowl', 8),
          ('Tofu scramble toast', ['tofu', 'whole grain toast', 'tomato'], '1 plate', 14),
        ];
      }
      return const [
        ('Greek yogurt and oats', ['Greek yogurt', 'oats', 'berries'], '1 bowl', 6),
        ('Egg toast with fruit', ['eggs', 'whole grain bread', 'apple'], '1 plate', 10),
      ];
    }

    if (type == 'Snack') {
      return const [
        ('Protein snack box', ['Greek yogurt', 'berries', 'almonds'], '1 box', 4),
        ('Hummus and vegetables', ['hummus', 'cucumber', 'carrots'], '1 plate', 5),
      ];
    }

    if (type == 'Lunch') {
      if (isVegetarian) {
        return const [
          ('Lentil quinoa bowl', ['lentils', 'quinoa', 'cucumber', 'olive oil'], '1 bowl', 18),
          ('Chickpea salad plate', ['chickpeas', 'tomato', 'greens', 'tahini'], '1 plate', 12),
        ];
      }
      if (isMiddleEastern) {
        return const [
          ('Chicken shawarma rice bowl', ['chicken breast', 'rice', 'yogurt sauce'], '1 bowl', 22),
          ('Grilled kebab salad', ['lean beef', 'greens', 'cucumber', 'tahini'], '1 plate', 18),
        ];
      }
      return const [
        ('Grilled chicken grain bowl', ['chicken breast', 'brown rice', 'greens'], '1 bowl', 20),
        ('Tuna potato salad', ['tuna', 'potato', 'greens', 'olive oil'], '1 plate', 14),
      ];
    }

    if (isVegetarian) {
      return const [
        ('Tofu vegetable stir fry', ['tofu', 'mixed vegetables', 'rice'], '1 plate', 20),
        ('Bean and sweet potato bowl', ['black beans', 'sweet potato', 'avocado'], '1 bowl', 18),
      ];
    }
    if (isMediterranean) {
      return const [
        ('Salmon with couscous', ['salmon', 'couscous', 'zucchini'], '1 plate', 20),
        ('Chicken feta salad', ['chicken breast', 'feta', 'greens', 'olive oil'], '1 plate', 12),
      ];
    }
    return const [
      ('Salmon rice plate', ['salmon', 'rice', 'broccoli'], '1 plate', 18),
      ('Turkey vegetable bowl', ['turkey', 'sweet potato', 'green beans'], '1 bowl', 16),
    ];
  }

  List<GroceryItem> _fallbackGroceries(UserSettings settings) {
    final restriction = settings.dietaryRestriction ?? 'none';
    final isVegan = restriction == 'vegan';
    final isVegetarian = restriction == 'vegetarian' || isVegan;

    final items = <GroceryItem>[
      GroceryItem(name: 'Oats', amount: '500g', category: 'Grains'),
      GroceryItem(name: 'Berries', amount: '2 packs', category: 'Produce'),
      GroceryItem(name: 'Brown rice', amount: '1 bag', category: 'Grains'),
      GroceryItem(name: 'Mixed greens', amount: '2 bags', category: 'Produce'),
      GroceryItem(name: 'Cucumber', amount: '4', category: 'Produce'),
      GroceryItem(name: 'Tomatoes', amount: '6', category: 'Produce'),
      GroceryItem(name: 'Olive oil', amount: '1 bottle', category: 'Oils'),
    ];

    if (isVegetarian) {
      items.addAll([
        GroceryItem(name: isVegan ? 'Tofu' : 'Greek yogurt', amount: '4 servings', category: 'Protein'),
        GroceryItem(name: 'Chickpeas', amount: '4 cans', category: 'Protein'),
        GroceryItem(name: 'Lentils', amount: '500g', category: 'Protein'),
      ]);
    } else {
      items.addAll([
        GroceryItem(name: 'Chicken breast', amount: '1.2kg', category: 'Protein'),
        GroceryItem(name: 'Salmon', amount: '4 fillets', category: 'Seafood'),
        GroceryItem(name: 'Eggs', amount: '12', category: 'Dairy'),
      ]);
    }

    return items;
  }

  String _dateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool get canRegenerate {
    const maxRegenPerWeek = 3;
    return _settingsProvider.isPro && _regenCountThisWeek < maxRegenPerWeek;
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
    _fallbackNotice = null;
    notifyListeners();
  }
}
