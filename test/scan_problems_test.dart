import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/resilience/app_failure.dart';
import 'package:snapcal/core/utils/date_utils.dart' as app_date;
import 'package:snapcal/core/utils/image_utils.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/snap/snap_controller.dart';
import 'package:snapcal/screens/snap/widgets/result_modal.dart';

void main() {
  group('a scan that fails says why', () {
    ScanProblem problemFor(AppFailureType type, {Object? raw}) =>
        SnapController.problemFor(
          AppFailure(type: type, message: 'x', rawError: raw),
        );

    test('no connection is reported as no connection, not "no food"', () {
      expect(problemFor(AppFailureType.offline), ScanProblem.offline);
    });

    test('a request that timed out points at a slow connection', () {
      expect(problemFor(AppFailureType.timeout), ScanProblem.slow);
    });

    test('a photo that cannot be read is said to be the photo', () {
      expect(
        problemFor(
          AppFailureType.unknown,
          raw: const UnsupportedImageException(),
        ),
        ScanProblem.unreadableImage,
      );
    });

    test('anything else is a failed scan', () {
      for (final type in [
        AppFailureType.server,
        AppFailureType.badResponse,
        AppFailureType.unauthorized,
        AppFailureType.unknown,
      ]) {
        expect(problemFor(type), ScanProblem.failed, reason: type.name);
      }
    });
  });

  test('a manual entry is filed by the time of day', () {
    String at(int hour) =>
        app_date.DateUtils.suggestedMealType(DateTime(2026, 9, 12, hour));
    expect(at(7), 'Breakfast');
    expect(at(11), 'Lunch');
    expect(at(16), 'Snack');
    expect(at(19), 'Dinner');
    expect(at(23), 'Snack');
    expect(at(3), 'Snack');
  });

  testWidgets('a single scanned food keeps its weight and nutrition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<NutritionResult>? saved;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [effectiveIsProProvider.overrideWith((ref) => true)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ResultModal(
              result: NutritionResult(
                foodName: 'Rice',
                portion: '180g',
                calories: 234,
                protein: 5,
                carbs: 50,
                fat: 1,
                weightG: 180,
                confidence: 0.9,
                nutritionMatchId: 'usda:rice',
                nutritionPer100g: const {
                  'calories': 130,
                  'protein': 2.7,
                  'carbs': 28,
                  'fat': 0.3,
                },
              ),
              onSave: (_, _, _, _, _, _) => fail('the single-item path'),
              onSaveAll: (items) => saved = items,
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byKey(const ValueKey('result-save-button')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(saved, hasLength(1));
    final item = saved!.single;
    expect(item.calories, 234);
    expect(item.weightG, 180);
    expect(item.confidence, 0.9);
    expect(item.nutritionMatchId, 'usda:rice');
    expect(item.nutritionPer100g, isNotNull);
  });
}
