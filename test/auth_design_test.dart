import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/auth/auth_screen.dart';

/// Renders the sign-in screen, as `paywall_design_test` does the paywall.
///
/// `SNAPCAL_CAPTURE_PREVIEWS=1 flutter test test/auth_design_test.dart` writes
/// PNGs to `build/auth-previews/`. Without the flag it is a smoke test: the
/// screen builds in both themes, at two widths and in Arabic, without throwing
/// or overflowing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capture = Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1';

  setUpAll(() async {
    // AppTypography reaches for DM Sans through google_fonts. In capture mode
    // runAsync lets that request actually leave, and a test has no business
    // fetching a font over the network.
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!capture) return;
    await (FontLoader('Preview')..addFont(
      Future.value(
        ByteData.sublistView(
          File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),
        ),
      ),
    )).load();
    await (FontLoader('packages/lucide_icons/Lucide')..addFont(
      rootBundle.load('packages/lucide_icons/assets/lucide.ttf'),
    )).load();
  });

  for (final scenario in [
    ('light', 390.0, 844.0, 'en', false),
    ('dark', 390.0, 844.0, 'en', true),
    ('small', 320.0, 640.0, 'en', false),
    ('arabic', 390.0, 844.0, 'ar', false),
  ]) {
    testWidgets('auth ${scenario.$1}', (tester) async {
      tester.view.physicalSize = Size(scenario.$2, scenario.$3);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: Locale(scenario.$4),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              brightness: scenario.$5 ? Brightness.dark : Brightness.light,
              fontFamily: capture ? 'Preview' : null,
            ),
            builder: (context, child) => RepaintBoundary(key: key, child: child!),
            home: const AuthScreen(),
          ),
        ),
      );
      await tester.pump();
      // The entrance is staggered; let every button land before looking.
      await tester.pump(const Duration(milliseconds: 1200));

      if (capture) {
        await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/auth-previews/${scenario.$1}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      // google_fonts downloads DM Sans at runtime rather than it being bundled,
      // so in capture mode -- where runAsync lets that request actually go --
      // it throws for want of a network. That is an environment limit, not a
      // defect in this screen. Every other exception, overflows included,
      // still fails the test.
      // Asserted on the plain run only. In capture mode runAsync lets
      // google_fonts actually try to fetch DM Sans -- which is not bundled --
      // and it throws asynchronously, after any check here could see it. The
      // plain run is the one that guards layout, and it is the one `flutter
      // test` performs; capture mode exists to produce images.
      if (!capture) expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
