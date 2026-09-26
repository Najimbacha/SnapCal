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
    await (FontLoader('WaznIcons')
      ..addFont(rootBundle.load('assets/fonts/WaznIcons.ttf'))).load();
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
        // Past the opening and the first flip to Pro.
        await tester.pump(const Duration(seconds: 3));
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
        // One card compares Free and Pro, and moves to Pro by itself once.
        expect(find.byKey(const ValueKey('paywall-compare')), findsOneWidget);
        expect(find.text('Wazn Pro'), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Full week'), findsOneWidget);
        expect(find.text('1 day'), findsNothing);

        // Both plans are in view beside the button, with no scrolling.
        await tester.ensureVisible(find.text('Monthly'));
        await tester.pump();
        await tester.tap(find.text('Monthly'));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.textContaining('Start Monthly'), findsOneWidget);
        expect(find.textContaining('free trial'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 9));
    });
  }
}
