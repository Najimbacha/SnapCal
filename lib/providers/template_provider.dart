import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/meal_template.dart';
import '../data/models/meal.dart';
import '../data/repositories/template_repository.dart';
import '../core/utils/date_utils.dart' as app_date;
import 'meal_provider.dart';

part 'template_provider.g.dart';

@Riverpod(keepAlive: true)
class Templates extends _$Templates {
  final Uuid _uuid = const Uuid();
  final TemplateRepository _repo = TemplateRepository();

  @override
  Future<List<MealTemplate>> build() async {
    // Routines sit in the Log's Quick add row; if their store cannot be
    // opened the Log still has to, just without them.
    try {
      await _repo.init();
      return _repo.getAll();
    } catch (e) {
      debugPrint('Routines unavailable: $e');
      return const [];
    }
  }

  /// How many routines a free account keeps; Pro keeps any number.
  static const freeLimit = 3;

  Future<MealTemplate> saveTemplate({
    required String name,
    required String emoji,
    required List<Meal> meals,
    String? mealType,
  }) async {
    final items =
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
            .toList();
    return saveTemplateFromItems(
      name: name,
      emoji: emoji,
      items: items,
      mealType: mealType,
    );
  }

  Future<MealTemplate> saveTemplateFromItems({
    required String name,
    required String emoji,
    required List<TemplateItem> items,
    String? mealType,
  }) async {
    final template = MealTemplate(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      items: items,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      mealType: mealType,
    );
    await _repo.save(template);
    state = AsyncData(_repo.getAll());
    return template;
  }

  /// Puts a just-deleted routine back, as it was.
  Future<void> restoreTemplate(MealTemplate template) async {
    await _repo.save(template);
    state = AsyncData(_repo.getAll());
  }

  /// Logs every food in [template] on [dateString] (today by default), into
  /// [mealType] or else the meal it was saved from. Returns the new meals'
  /// ids, so the whole routine can be undone at once.
  Future<List<String>> logFromTemplate(
    MealTemplate template, {
    String? dateString,
    String? mealType,
  }) async {
    final mealLog = ref.read(mealLogProvider.notifier);
    final ids = <String>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final (i, item) in template.items.indexed) {
      final id = _uuid.v4();
      ids.add(id);
      await mealLog.addMeal(
        Meal(
          id: id,
          foodName: item.foodName,
          calories: item.calories,
          macros: Macros(
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
          ),
          portion: item.servingSize,
          dateString: dateString ?? app_date.DateUtils.getTodayString(),
          // A millisecond apart, so they keep the routine's order.
          timestamp: now + i,
          mealType: mealType ?? template.mealType,
        ),
      );
    }
    template.usageCount++;
    await _repo.save(template);
    state = AsyncData(_repo.getAll());
    return ids;
  }

  Future<void> deleteTemplate(String id) async {
    await _repo.delete(id);
    state = AsyncData(_repo.getAll());
  }

  Future<void> updateTemplate(String id, {String? name, String? emoji}) async {
    final current = state.valueOrNull ?? [];
    // The template may have been deleted on another device or the cached list
    // may be stale; a missing id must not throw inside the provider (BUG-013).
    final template = current.firstWhereOrNull((t) => t.id == id);
    if (template == null) return;
    final updated = MealTemplate(
      id: template.id,
      name: name ?? template.name,
      emoji: emoji ?? template.emoji,
      items: template.items,
      createdAt: template.createdAt,
      usageCount: template.usageCount,
      mealType: template.mealType,
    );
    await _repo.save(updated);
    state = AsyncData(_repo.getAll());
  }

  bool canAddTemplate(bool isPro) {
    final count = state.valueOrNull?.length ?? 0;
    if (isPro) return true;
    return count < freeLimit;
  }

  /// Applies templates changed on the user's other devices.
  Future<bool> pullFromCloud() async {
    await future;
    final changed = await _repo.pullFromCloud();
    if (changed) state = AsyncData(_repo.getAll());
    return changed;
  }

  /// Uploads every template on this phone to the signed-in account.
  Future<void> pushAllLocal() async {
    await future;
    await _repo.pushAllLocal();
  }

  Future<void> clear() async {
    await _repo.clear();
    state = const AsyncData([]);
  }
}
