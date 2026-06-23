import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/meal_template.dart';
import '../data/models/meal.dart';
import '../data/repositories/template_repository.dart';
import '../core/utils/date_utils.dart' as app_date;
import 'meal_provider.dart';
import 'settings_provider.dart';

part 'template_provider.g.dart';

@Riverpod(keepAlive: true)
class Templates extends _$Templates {
  final Uuid _uuid = const Uuid();
  final TemplateRepository _repo = TemplateRepository();

  @override
  Future<List<MealTemplate>> build() async {
    await _repo.init();
    return _repo.getAll();
  }

  Future<void> saveTemplate({
    required String name,
    required String emoji,
    required List<Meal> meals,
  }) async {
    final items = meals.map((m) => TemplateItem(
      foodName: m.foodName, calories: m.calories,
      protein: m.macros.protein, carbs: m.macros.carbs,
      fat: m.macros.fat, servingSize: m.portion,
    )).toList();
    await saveTemplateFromItems(name: name, emoji: emoji, items: items);
  }

  Future<void> saveTemplateFromItems({
    required String name,
    required String emoji,
    required List<TemplateItem> items,
  }) async {
    final template = MealTemplate(
      id: _uuid.v4(), name: name, emoji: emoji,
      items: items, createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.save(template);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> logFromTemplate(MealTemplate template) async {
    final mealLog = ref.read(mealLogProvider.notifier);
    for (final item in template.items) {
      await mealLog.addMeal(Meal(
        id: _uuid.v4(),
        foodName: item.foodName,
        calories: item.calories,
        macros: Macros(protein: item.protein, carbs: item.carbs, fat: item.fat),
        portion: item.servingSize,
        dateString: app_date.DateUtils.getTodayString(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    template.usageCount++;
    await _repo.save(template);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> deleteTemplate(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> updateTemplate(String id, {String? name, String? emoji}) async {
    final current = state.valueOrNull ?? [];
    final template = current.firstWhere((t) => t.id == id);
    final updated = MealTemplate(
      id: template.id, name: name ?? template.name,
      emoji: emoji ?? template.emoji, items: template.items,
      createdAt: template.createdAt, usageCount: template.usageCount,
    );
    await _repo.save(updated);
    state = AsyncData(await _repo.getAll());
  }

  bool canAddTemplate(bool isPro) {
    final count = state.valueOrNull?.length ?? 0;
    if (isPro) return true;
    return count < 3;
  }

  Future<void> clear() async {
    await _repo.clear();
    state = const AsyncData([]);
  }
}
