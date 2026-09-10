import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/meal_template.dart';
import '../services/cloud_record_sync.dart';

class TemplateRepository {
  static const String _boxName = 'templates_box';
  Box<MealTemplate>? _box;
  final CloudRecordSync _cloud = CloudRecordSync('mealTemplates');

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
    _inBackground(_cloud.push(template.id, template.toJson()));
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
    _inBackground(_cloud.remove(id));
  }

  /// Applies templates saved or deleted on the user's other devices. Returns
  /// whether anything on this phone changed.
  Future<bool> pullFromCloud() async {
    await init();
    final box = _box;
    if (box == null) return false;
    return _cloud.pull(
      upsert: (id, data) async {
        try {
          await box.put(id, MealTemplate.fromJson({...data, 'id': id}));
          return true;
        } catch (e) {
          debugPrint('Skipping unreadable template $id: $e');
          return false;
        }
      },
      delete: (id) async {
        if (!box.containsKey(id)) return false;
        await box.delete(id);
        return true;
      },
    );
  }

  /// Uploads every template on this phone to the signed-in account.
  Future<void> pushAllLocal() async {
    await init();
    final box = _box;
    if (box == null) return;
    await _cloud.pushAll({
      for (final template in box.values) template.id: template.toJson(),
    });
  }

  /// Local only: this is the sign-out and reset path, which must not reach
  /// into the account and delete the user's templates there.
  Future<void> clear() async {
    await _box?.clear();
  }

  void _inBackground(Future<void> write) {
    unawaited(
      write.catchError((Object e) => debugPrint('Template sync failed: $e')),
    );
  }
}
