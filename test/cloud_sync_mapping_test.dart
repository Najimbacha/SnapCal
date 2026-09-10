import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/body_metric.dart';
import 'package:snapcal/data/models/meal_template.dart';
import 'package:snapcal/data/models/water_log.dart';
import 'package:snapcal/data/repositories/water_repository.dart';
import 'package:snapcal/providers/metrics_provider.dart';

// What each synced record sends to the cloud has to match the field lists in
// firestore.rules exactly: an extra field gets the whole write refused.
void main() {
  group('water log', () {
    test('round-trips through the cloud shape', () {
      final log = WaterLog(
        dateString: '2026-09-11',
        amountMl: 250,
        timestamp: 1789000000000,
      );
      final cloud = WaterRepository.toCloud(log);

      expect(
        cloud.keys,
        unorderedEquals(['dateString', 'amountMl', 'timestamp']),
      );
      final back = WaterRepository.fromCloud(cloud)!;
      expect(back.dateString, log.dateString);
      expect(back.amountMl, log.amountMl);
      expect(back.timestamp, log.timestamp);
    });

    test('accepts numbers Firestore returns as doubles', () {
      final back = WaterRepository.fromCloud({
        'dateString': '2026-09-11',
        'amountMl': 250.0,
        'timestamp': 1789000000000.0,
      });
      expect(back?.amountMl, 250);
    });

    test('ignores a record missing a field', () {
      expect(WaterRepository.fromCloud({'amountMl': 250}), isNull);
    });
  });

  group('weight history', () {
    test('round-trips, without uploading photo paths', () {
      final metric = BodyMetric(
        id: 'm1',
        date: DateTime.fromMillisecondsSinceEpoch(1789000000000),
        weight: 72.5,
        bodyFat: 18.0,
        photoFrontPath: '/data/user/0/app/front.jpg',
      );
      final cloud = BodyMetrics.toCloud(metric);

      expect(
        cloud.keys,
        unorderedEquals(['date', 'weight', 'bodyFat', 'note']),
      );
      expect(cloud.values, isNot(contains('/data/user/0/app/front.jpg')));

      final back = BodyMetrics.fromCloud('m1', cloud)!;
      expect(back.id, 'm1');
      expect(back.date, metric.date);
      expect(back.weight, 72.5);
      expect(back.bodyFat, 18.0);
      expect(back.photoFrontPath, isNull);
    });

    test(
      "keeps this phone's photos when a weigh-in is updated from the cloud",
      () {
        final local = BodyMetric(
          id: 'm1',
          date: DateTime.fromMillisecondsSinceEpoch(1789000000000),
          weight: 72.5,
          photoFrontPath: '/front.jpg',
        );
        final back =
            BodyMetrics.fromCloud('m1', {
              'date': 1789000000000,
              'weight': 71,
            }, local: local)!;
        expect(back.weight, 71.0);
        expect(back.photoFrontPath, '/front.jpg');
      },
    );
  });

  group('meal template', () {
    test('uploads only the fields the rules allow', () {
      final template = MealTemplate(
        id: 't1',
        name: 'Breakfast',
        emoji: '🍳',
        items: [
          TemplateItem(
            foodName: 'Eggs',
            calories: 140,
            protein: 12,
            carbs: 1,
            fat: 10,
          ),
        ],
        createdAt: 1789000000000,
        usageCount: 3,
      );
      final cloud = template.toJson();

      // `id` is one of the bookkeeping fields every synced record carries.
      expect(
        cloud.keys,
        unorderedEquals([
          'id',
          'name',
          'emoji',
          'items',
          'createdAt',
          'usageCount',
        ]),
      );

      // A pull hands back the fields without the bookkeeping ones.
      final pulled = Map<String, dynamic>.of(cloud)..remove('id');
      final back = MealTemplate.fromJson({...pulled, 'id': 't1'});
      expect(back.name, 'Breakfast');
      expect(back.items.single.foodName, 'Eggs');
      expect(back.usageCount, 3);
    });
  });
}
