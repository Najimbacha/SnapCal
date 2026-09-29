import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/meal_image_transaction.dart';

void main() {
  test(
    'failed meal persistence removes the image written for that attempt',
    () async {
      final removed = <String>[];

      await expectLater(
        MealImageTransaction.run<void>(
          persistImage: () async => 'meal_images/failed.jpg',
          saveMeal: (_) async => throw StateError('disk full'),
          removeImage: (path) async => removed.add(path),
        ),
        throwsStateError,
      );

      expect(removed, ['meal_images/failed.jpg']);
    },
  );
}
