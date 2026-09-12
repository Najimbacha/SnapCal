import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/paywall/paywall_screen.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capture = Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1';
  const annual = Package(
    'annual',
    PackageType.annual,
    StoreProduct(
      'annual',
      '',
      'Yearly',
      119.99,
      'SAR 119.99',
      'SAR',
      subscriptionPeriod: 'P1Y',
    ),
    PresentedOfferingContext('test', null, null),
  );
  const monthly = Package(
    'monthly',
    PackageType.monthly,
    StoreProduct(
      'monthly',
      '',
      'Monthly',
      19.99,
      'SAR 19.99',
      'SAR',
      subscriptionPeriod: 'P1M',
    ),
    PresentedOfferingContext('test', null, null),
  );
  const offering = Offering(
    'test',
    '',
    {},
    [annual, monthly],
    annual: annual,
    monthly: monthly,
  );
  setUpAll(() async {
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
    ('dark', 390.0, 844.0, 1.0, 'en', true),
    ('light', 390.0, 844.0, 1.0, 'en', false),
    ('small', 320.0, 640.0, 1.0, 'en', true),
    ('large-text', 320.0, 740.0, 1.6, 'en', true),
    ('arabic', 390.0, 844.0, 1.0, 'ar', true),
    ('short-large', 320.0, 568.0, 2.0, 'en', false),
    ('landscape', 640.0, 360.0, 2.0, 'ar', true),
    ('spanish', 360.0, 640.0, 1.5, 'es', false),
    ('french', 320.0, 568.0, 2.0, 'fr', true),
  ]) {
    testWidgets('paywall ${scenario.$1}', (tester) async {
      tester.view.physicalSize = Size(scenario.$2, scenario.$3);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectiveIsProProvider.overrideWith((ref) => false),
            paywallOfferingsLoaderProvider.overrideWithValue(
              () async =>
                  const Offerings({'test': offering}, current: offering),
            ),
          ],
          child: MaterialApp(
            locale: Locale(scenario.$5),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              brightness: scenario.$6 ? Brightness.dark : Brightness.light,
              fontFamily: capture ? 'Preview' : null,
            ),
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scenario.$4)),
                  child: child!,
                ),
            home: RepaintBoundary(key: key, child: const PaywallScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.runAsync(() async {
        for (final widget
            in tester.widgetList<Image>(find.byType(Image)).toList()) {
          await precacheImage(widget.image, key.currentContext!);
        }
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      if (capture) {
        // Past the rest point (0.92 of an 8.2s reveal), so the captured frame
        // is the one people actually sit in front of: every label placed and
        // the total counted, rather than a third of the way through.
        await tester.pump(const Duration(seconds: 8));
        await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/paywall-previews/${scenario.$1}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      if (scenario.$5 == 'en') {
        // The scan demo now runs full width at the top of the screen instead
        // of in a compact box beside the macro bars. Same widget, same job --
        // the key is what changed.
        expect(find.byKey(const ValueKey('paywall-scan-hero')), findsOneWidget);
        // The calorie figure now lives in the hero's detection chip: a
        // RichText, which find.textContaining ignores unless asked, and one
        // that fades in partway through the scan and back out before the
        // slide changes. Wait for it rather than guessing a frame -- the
        // capture path above has already pumped, so a fixed wait lands in a
        // different place depending on the mode.
        Finder detectedKcal() => find.textContaining('248', findRichText: true);
        var sawKcal = false;
        for (var tick = 0; tick < 32 && !sawKcal; tick++) {
          await tester.pump(const Duration(milliseconds: 250));
          sawKcal = detectedKcal().evaluate().isNotEmpty;
        }
        expect(
          sawKcal,
          isTrue,
          reason: 'the hero should name the calories it detected',
        );
        // The hero used to rotate through three photographs and this asserted
        // that it did. It is one photograph now, scanned once and then held:
        // the dots were decoration with no swipe and no tap behind them, and a
        // decision screen that keeps moving asks to be watched rather than
        // read. So the assertion inverts -- after the reveal has run well past
        // where it used to loop, the same plate is on screen and its labels
        // are still there rather than having faded out for a successor.
        final settledAsset =
            tester
                .widgetList<Image>(find.byType(Image))
                .map((i) => i.image)
                .toList();
        await tester.pump(const Duration(seconds: 9));
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester
              .widgetList<Image>(find.byType(Image))
              .map((i) => i.image)
              .toList(),
          settledAsset,
          reason: 'the hero should rest on its plate, not cycle',
        );
        expect(
          detectedKcal(),
          findsOneWidget,
          reason: 'the scan should hold its labels once it has finished',
        );
        final scrollableState = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scrollableState.position.jumpTo(0);
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('Monthly'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('Monthly')),
          alignment: 0.15,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Monthly'));
        await tester.pump(const Duration(milliseconds: 300));
        scrollableState.position.jumpTo(
          scrollableState.position.maxScrollExtent,
        );
        await tester.pump();
        expect(find.textContaining('Start Monthly'), findsOneWidget);
        expect(find.textContaining('Start Free Trial'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 9));
    });
  }
}
