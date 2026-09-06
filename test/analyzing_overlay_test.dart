import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/snap/snap_controller.dart';
import 'package:snapcal/screens/snap/widgets/analyzing_overlay.dart';

class _Controller extends Fake implements SnapController {
  final Uint8List? bytes;
  _Controller(this.bytes);
  @override
  Uint8List? get capturedImageBytes => bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1') {
      final font = FontLoader('Preview');
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),
          ),
        ),
      );
      await font.load();
      final icons = FontLoader('packages/lucide_icons/Lucide');
      icons.addFont(rootBundle.load('packages/lucide_icons/assets/lucide.ttf'));
      await icons.load();
    }
  });
  for (final scenario in [
    ('phone', const Size(390, 844), false, 1.0, 'en'),
    ('compact', const Size(320, 568), false, 1.0, 'en'),
    ('accessible', const Size(320, 568), true, 2.0, 'en'),
    ('arabic', const Size(390, 844), true, 1.0, 'ar'),
    ('landscape', const Size(844, 390), false, 1.0, 'en'),
  ]) {
    testWidgets('waiting screen ${scenario.$1}', (tester) async {
      tester.view.physicalSize = scenario.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes =
          File(
            'assets/images/paywall/onboarding_grilled_chicken_bowl.png',
          ).readAsBytesSync();
      final boundary = GlobalKey();
      var manual = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(scenario.$5),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            fontFamily:
                Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1'
                    ? 'Preview'
                    : null,
            brightness: scenario.$3 ? Brightness.dark : Brightness.light,
          ),
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scenario.$4),
                  disableAnimations: scenario.$1 == 'accessible',
                ),
                child: child!,
              ),
          home: RepaintBoundary(
            key: boundary,
            child: AnalyzingOverlay(
              controller: _Controller(bytes),
              onManualEntry: () => manual = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.runAsync(() async {
        await precacheImage(MemoryImage(bytes), boundary.currentContext!);
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('analyzing-manual-entry')),
        findsNothing,
      );
      if (Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1') {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/scan-previews/${scenario.$1}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pump(const Duration(seconds: 11));
      await tester.pump(const Duration(milliseconds: 350));
      final button = find.byKey(const ValueKey('analyzing-manual-entry'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      expect(manual, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
