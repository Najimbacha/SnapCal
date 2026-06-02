import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/meal_template.dart';
import '../data/models/meal.dart';
import '../data/repositories/template_repository.dart';
import 'meal_provider.dart';
import 'settings_provider.dart';
import '../core/utils/date_utils.dart' as app_date;

/// Provider for managing meal templates ("My Routines")
class TemplateProvider with ChangeNotifier {
  final TemplateRepository _repository = TemplateRepository();
  final Uuid _uuid = const Uuid();

  List<MealTemplate> _templates = [];

  List<MealTemplate> get templates =>
      [..._templates]..sort((a, b) => b.usageCount.compareTo(a.usageCount));

  bool get hasTemplates => _templates.isNotEmpty;

  Future<void> init() async {
    await _repository.init();
    _templates = _repository.getAll();
    notifyListeners();
  }

  /// Save a new template from a list of meals
  Future<void> saveTemplate({
    required String name,
    required String emoji,
    required List<Meal> meals,
  }) async {
    final template = MealTemplate(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      items:
          meals
              .map(
                (m) => TemplateItem(
                  foodName: m.foodName,
                  calories: m.calories,
                  protein: m.macros.protein,
                  carbs: m.macros.carbs,
                  fat: m.macros.fat,
                  servingSize: m.portion,
                ),
              )
              .toList(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _repository.save(template);
    _templates = _repository.getAll();
    notifyListeners();
  }

  /// Save a template from manually created items
  Future<void> saveTemplateFromItems({
    required String name,
    required String emoji,
    required List<TemplateItem> items,
  }) async {
    final template = MealTemplate(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      items: items,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _repository.save(template);
    _templates = _repository.getAll();
    notifyListeners();
  }

  /// Log all items from a template as meals
  Future<void> logFromTemplate(
    MealTemplate template,
    MealProvider mealProvider,
    SettingsProvider settings,
  ) async {
    for (final item in template.items) {
      await mealProvider.addMeal(
        foodName: item.foodName,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fat: item.fat,
        portion: item.servingSize,
        dateString: app_date.DateUtils.getTodayString(),
        settings: settings,
      );
    }

    // Increment usage count
    template.usageCount++;
    await _repository.save(template);
    _templates = _repository.getAll();
    notifyListeners();
  }

  /// Delete a template
  Future<void> deleteTemplate(String id) async {
    await _repository.delete(id);
    _templates = _repository.getAll();
    notifyListeners();
  }

  /// Update template name/emoji
  Future<void> updateTemplate(String id, {String? name, String? emoji}) async {
    final template = _templates.firstWhere((t) => t.id == id);

    final updated = MealTemplate(
      id: template.id,
      name: name ?? template.name,
      emoji: emoji ?? template.emoji,
      items: template.items,
      createdAt: template.createdAt,
      usageCount: template.usageCount,
    );
    await _repository.save(updated);
    _templates = _repository.getAll();
    notifyListeners();
  }

  /// Check if user can add more templates (free tier limit)
  bool canAddTemplate(bool isPro) {
    if (isPro) return true;
    return _templates.length < 3;
  }

  /// Clear all templates (logout)
  Future<void> clear() async {
    await _repository.clear();
    _templates = [];
    notifyListeners();
  }
}
