import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/snap/widgets/result_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capture = Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1';
  setUpAll(() async {
    if (!capture) return;
    final font = FontLoader('Preview')..addFont(
      Future.value(
        ByteData.sublistView(
          File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),
        ),
      ),
    );
    await font.load();
    final icons = FontLoader('packages/lucide_icons/Lucide')
      ..addFont(rootBundle.load('packages/lucide_icons/assets/lucide.ttf'));
    await icons.load();
  });
  for (final scenario in [
    ('free', false, false, 'en', 390.0, 1.0),
    ('pro', true, false, 'en', 390.0, 1.0),
    ('pro-dark', true, true, 'en', 390.0, 1.0),
    ('free-arabic', false, true, 'ar', 320.0, 1.0),
    ('free-large-text', false, false, 'en', 320.0, 1.6),
  ]) {
    testWidgets('result ${scenario.$1}', (tester) async {
      tester.view.physicalSize = Size(scenario.$5, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes =
          File(
            'assets/images/paywall/onboarding_grilled_chicken_bowl.png',
          ).readAsBytesSync();
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectiveIsProProvider.overrideWith((ref) => scenario.$2),
          ],
          child: MaterialApp(
            locale: Locale(scenario.$4),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              fontFamily: capture ? 'Preview' : null,
              brightness: scenario.$3 ? Brightness.dark : Brightness.light,
            ),
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scenario.$6)),
                  child: child!,
                ),
            home: RepaintBoundary(
              key: key,
              child: ResultModal(
                imageBytes: bytes,
                results: [
                  NutritionResult(
                    foodName: 'Grilled chicken',
                    portion: '150g',
                    calories: 248,
                    protein: 46,
                    carbs: 0,
                    fat: 5,
                    healthScore: 8,
                  ),
                  NutritionResult(
                    foodName: 'Rice',
                    portion: '150g',
                    calories: 195,
                    protein: 4,
                    carbs: 42,
                    fat: 1,
                    healthScore: 7,
                  ),
                  NutritionResult(
                    foodName: 'Avocado',
                    portion: '50g',
                    calories: 80,
                    protein: 1,
                    carbs: 4,
                    fat: 7,
                    healthScore: 8,
                  ),
                ],
                onSave: (_, _, _, _, _, _) {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(MemoryImage(bytes), key.currentContext!),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      if (capture) {
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/result-previews/${scenario.$1}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
