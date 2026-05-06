import 'package:hive/hive.dart';
import '../models/meal_template.dart';

class TemplateRepository {
  static const String _boxName = 'templates_box';
  Box<MealTemplate>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<MealTemplate>(_boxName);
    } else {
      _box = Hive.box<MealTemplate>(_boxName);
    }
  }

  List<MealTemplate> getAll() {
    return _box?.values.toList() ?? [];
  }

  Future<void> save(MealTemplate template) async {
    await _box?.put(template.id, template);
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}
