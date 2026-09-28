import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/services/connectivity_service.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/snap/snap_controller.dart';
import 'package:snapcal/screens/snap/widgets/result_modal.dart';

/// A gallery whose answer the test decides.
class _Gallery extends SnapController {
  _Gallery(this.pick);

  final Future<XFile?> Function() pick;
  int opened = 0;

  @override
  Future<XFile?> pickImage() {
    opened++;
    return pick();
  }
}

class _Online implements ConnectivityService {
  @override
  Future<bool> refreshReachability({bool force = false}) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Meals extends Fake implements MealLog {}

Uint8List _jpeg({String? takenAt}) {
  final image = img.Image(width: 16, height: 16);
  img.fill(image, color: img.ColorRgb8(200, 120, 60));
  if (takenAt != null) image.exif.exifIfd['DateTimeOriginal'] = takenAt;
  return img.encodeJpg(image);
}

void main() {
  group('photo date', () {
    test('reads when a photo was taken', () {
      expect(
        SnapController.readPhotoDate(_jpeg(takenAt: '2026:09:27 20:14:03')),
        DateTime(2026, 9, 27, 20, 14, 3),
      );
    });

    test('a photo without a date has none', () {
      expect(SnapController.readPhotoDate(_jpeg()), isNull);
      expect(
        SnapController.readPhotoDate(Uint8List.fromList([1, 2, 3])),
        isNull,
      );
    });

    test('only an older photo moves the meal', () {
      final now = DateTime(2026, 9, 28, 9, 0);
      DateTime? at(String exif) =>
          SnapController.mealTimeFromPhoto(_jpeg(takenAt: exif), now);

      // Last night's dinner goes to last night.
      expect(at('2026:09:27 20:14:03'), DateTime(2026, 9, 27, 20, 14, 3));
      // Minutes ago is just now.
      expect(at('2026:09:28 08:40:00'), isNull);
      // Too old, or from the future (a wrong camera clock): now.
      expect(at('2026:09:10 12:00:00'), isNull);
      expect(at('2026:09:29 12:00:00'), isNull);
    });
  });

  group('gallery scan', () {
    Future<List<ScanProblem>> run(_Gallery c, {List<bool>? analyzing}) async {
      final problems = <ScanProblem>[];
      c.onStateChanged = () => analyzing?.add(c.isAnalyzing);
      await c.pickFromGallery(
        mealProvider: _Meals(),
        settingsProvider: UserSettings.defaults(),
        isPro: false,
        connectivity: _Online(),
        onShowPaywall: () {},
        onShowResult: () {},
        onProblem: problems.add,
      );
      return problems;
    }

    test('a gallery that will not open says so', () async {
      final c = _Gallery(() async => throw Exception('no access'));
      expect(await run(c), [ScanProblem.galleryUnavailable]);
      expect(c.isAnalyzing, isFalse);
    });

    test('backing out of the gallery does nothing', () async {
      final c = _Gallery(() async => null);
      final analyzing = <bool>[];
      expect(await run(c, analyzing: analyzing), isEmpty);
      expect(analyzing, isNot(contains(true)));
    });

    test('the waiting screen shows as soon as a photo is chosen', () async {
      final c = _Gallery(
        () async => XFile.fromData(Uint8List.fromList([1, 2, 3])),
      );
      final analyzing = <bool>[];
      // Unreadable bytes, so the scan stops before any upload.
      expect(await run(c, analyzing: analyzing), [ScanProblem.unreadableImage]);
      expect(analyzing.first, isTrue);
      expect(c.isAnalyzing, isFalse);
    });

    test('a second tap does not open a second gallery', () async {
      final pending = Completer<XFile?>();
      final c = _Gallery(() => pending.future);
      final first = run(c);
      final second = run(c);
      await second;
      pending.complete(null);
      await first;
      expect(c.opened, 1);
    });
  });

  testWidgets('the result says when an older photo will be logged', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [effectiveIsProProvider.overrideWith((ref) => true)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ResultModal(
              imageBytes: _jpeg(),
              eatenAtLabel: 'From your photo: Yesterday · 8:14 PM',
              result: NutritionResult(
                foodName: 'Grilled steak',
                portion: '180g',
                calories: 350,
                protein: 40,
                carbs: 0,
                fat: 20,
              ),
              onSave: (_, _, _, _, _, _) {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('From your photo: Yesterday · 8:14 PM'), findsOneWidget);
  });
}
