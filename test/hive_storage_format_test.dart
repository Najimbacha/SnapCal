import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/data/models/meal.dart';

/// The Hive adapters in `*.g.dart` are kept by hand: the project no longer
/// runs hive_generator. A field added to a model but not to its adapter is
/// saved nowhere, and silently empty after the next restart -- which is how
/// a meal's weight and per-100 g nutrition were lost.

Set<int> _indices(String source, RegExp pattern) =>
    pattern.allMatches(source).map((m) => int.parse(m.group(1)!)).toSet();

/// A meal adapter as it was before fields 17 to 19, to write old records.
class _LegacyMealAdapter extends TypeAdapter<Meal> {
  @override
  final int typeId = 1;

  @override
  Meal read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, Meal obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.dateString)
      ..writeByte(3)
      ..write(obj.imageUri)
      ..writeByte(4)
      ..write(obj.foodName)
      ..writeByte(5)
      ..write(obj.calories)
      ..writeByte(6)
      ..write(obj.macros)
      ..writeByte(7)
      ..write(obj.synced)
      ..writeByte(8)
      ..write(obj.ingredients)
      ..writeByte(9)
      ..write(obj.prepTimeMins)
      ..writeByte(10)
      ..write(obj.mealType)
      ..writeByte(11)
      ..write(obj.portion)
      ..writeByte(12)
      ..write(obj.scanConfidence)
      ..writeByte(13)
      ..write(obj.scanSource)
      ..writeByte(14)
      ..write(obj.aiRationale)
      ..writeByte(15)
      ..write(obj.originalCalories)
      ..writeByte(16)
      ..write(obj.userCorrected);
  }
}

void main() {
  test('every saved field of every stored model is written and read by its '
      'adapter', () {
    final models =
        Directory('lib/data/models')
            .listSync()
            .whereType<File>()
            .where(
              (f) =>
                  f.path.endsWith('.dart') &&
                  !f.path.endsWith('.g.dart') &&
                  f.readAsStringSync().contains('@HiveType'),
            )
            .toList();
    expect(models, isNotEmpty);

    for (final model in models) {
      final source = model.readAsStringSync();
      final adapter =
          File(
            model.path.replaceFirst(RegExp(r'\.dart$'), '.g.dart'),
          ).readAsStringSync();
      // Split both files per class so two types in one file are compared
      // field by field.
      final classes = RegExp(
        r'@HiveType\(typeId: (\d+)\)[\s\S]*?(?=@HiveType|$)',
      ).allMatches(source);
      for (final type in classes) {
        final typeId = type.group(1);
        final fields = _indices(type.group(0)!, RegExp(r'@HiveField\((\d+)'));
        final adapterClass =
            RegExp(
              'typeId = $typeId;'
              r'[\s\S]*?int get hashCode',
            ).firstMatch(adapter)!.group(0)!;
        final written = _indices(
          adapterClass.split('void write(').last,
          RegExp(r'\.\.writeByte\((\d+)\)\s*\.\.write\('),
        );
        final read = _indices(adapterClass, RegExp(r'fields\[(\d+)\]'));
        final where = '${model.path} typeId $typeId';
        expect(written, fields, reason: '$where: fields not written');
        expect(read, fields, reason: '$where: fields not read');
        expect(
          adapterClass,
          contains('..writeByte(${fields.length})'),
          reason: '$where: field count',
        );
      }
    }
  });

  test('meals saved before weight and per-100 g were stored still open, '
      'without them', () async {
    final directory = await Directory.systemTemp.createTemp('legacy_meals_');
    addTearDown(() => directory.delete(recursive: true));
    Hive.init(directory.path);
    Hive.registerAdapter(MacrosAdapter());
    Hive.registerAdapter<Meal>(_LegacyMealAdapter());
    var box = await Hive.openBox<Meal>('meals');
    await box.put(
      'old',
      Meal(
        id: 'old',
        timestamp: 1,
        dateString: '2025-01-01',
        foodName: 'Old rice',
        calories: 210,
        macros: Macros(protein: 4, carbs: 45, fat: 1),
        mealType: 'Lunch',
        userCorrected: true,
      ),
    );
    await Hive.close();

    Hive.registerAdapter(MealAdapter(), override: true);
    box = await Hive.openBox<Meal>('meals');
    final meal = box.get('old')!;
    expect(meal.foodName, 'Old rice');
    expect(meal.calories, 210);
    expect(meal.macros.carbs, 45);
    expect(meal.userCorrected, isTrue);
    expect(meal.weightG, isNull);
    expect(meal.nutritionPer100g, isNull);

    // Saved again, it keeps the new fields from then on.
    await box.put('old', meal.copyWith(weightG: 180));
    await Hive.close();
    box = await Hive.openBox<Meal>('meals');
    expect(box.get('old')!.weightG, 180);
    await Hive.close();
  });
}
