import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/bottom_nav_bar.dart';

/// The shipped bottom bar, four tabs, as a picture and as a fit check.
///
/// `SNAPCAL_CAPTURE_PREVIEWS=1 flutter test test/nav_bar_preview_test.dart`
/// writes PNGs to `build/nav-previews/`. Without that variable the file still
/// earns its place: four labels either side of the scan notch is the layout
/// most likely to overflow, so a narrow phone is checked on every run.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capture = Platform.environment['SNAPCAL_CAPTURE_PREVIEWS'] == '1';

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!capture) return;
    const segoe = 'C:/Windows/Fonts';
    for (final (family, file) in [
      ('DMSans_regular', 'segoeui.ttf'),
      ('DMSans_500', 'segoeui.ttf'),
      ('DMSans_600', 'seguisb.ttf'),
      ('DMSans_700', 'segoeuib.ttf'),
      ('DMSans_800', 'segoeuib.ttf'),
      ('DMSans_900', 'seguibl.ttf'),
      ('DMSans', 'segoeui.ttf'),
    ]) {
      await (FontLoader(family)..addFont(
        Future.value(
          ByteData.sublistView(File('$segoe/$file').readAsBytesSync()),
        ),
      )).load();
    }
    await (FontLoader('packages/lucide_icons/Lucide')..addFont(
      rootBundle.load('packages/lucide_icons/assets/lucide.ttf'),
    )).load();
  });

  for (final (name, dark) in [('light', false), ('dark', true)]) {
    testWidgets('nav bar sheet $name', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final key = GlobalKey();
      await tester.pumpWidget(
        _App(dark: dark, capture: capture, boundaryKey: key, child: _sheet),
      );
      // The bar fades and slides itself in.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);

      if (!capture) return;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/nav-previews/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    });
  }

  testWidgets('four tabs fit a narrow phone, resting and mid-animation', (
    tester,
  ) async {
    // 320dp is the narrowest phone worth supporting.
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const _App(dark: false, capture: false, child: _LiveBar()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Home to Profile moves the pill furthest, so it is the hand-over worth
    // catching part-way through.
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 130));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

const _sheet = Padding(
  padding: EdgeInsets.symmetric(vertical: 14),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Caption('Resting on Home'),
      _BarFrame(currentIndex: 0),
      SizedBox(height: 18),
      _Caption('On Stats — the pill moved, the label went bold'),
      _BarFrame(currentIndex: 2),
      SizedBox(height: 18),
      _Caption('On Profile'),
      _BarFrame(currentIndex: 3),
    ],
  ),
);

/// One live bar that answers taps, for the fit check.
class _LiveBar extends StatefulWidget {
  const _LiveBar();

  @override
  State<_LiveBar> createState() => _LiveBarState();
}

class _LiveBarState extends State<_LiveBar> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => _BarFrame(
    currentIndex: _index,
    onTap: (index) => setState(() => _index = index),
  );
}

/// The bar as the shell mounts it: docked scan button, page behind.
class _BarFrame extends StatelessWidget {
  const _BarFrame({required this.currentIndex, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 124,
      child: Scaffold(
        // A shade off the page colour, so the bar's own edge reads.
        backgroundColor:
            isDark ? const Color(0xFF101113) : const Color(0xFFEFEEE9),
        extendBody: true,
        body: const SizedBox.shrink(),
        floatingActionButton: Transform.translate(
          offset: const Offset(0, 28),
          child: const _ScanStandIn(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onTap: onTap ?? _ignore,
        ),
      ),
    );
  }

  static void _ignore(int _) {}
}

class _App extends StatelessWidget {
  const _App({
    required this.dark,
    required this.capture,
    required this.child,
    this.boundaryKey,
  });

  final bool dark;
  final bool capture;
  final Widget child;
  final GlobalKey? boundaryKey;

  @override
  Widget build(BuildContext context) {
    final body = RepaintBoundary(
      key: boundaryKey,
      child: Material(
        color: dark ? Colors.black : const Color(0xFFFBFCFA),
        child: SafeArea(child: child),
      ),
    );
    // A router is here because screens in the app ask whether they can pop.
    return MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: dark ? Colors.black : const Color(0xFFFBFCFA),
        fontFamily: capture ? 'DMSans_regular' : null,
      ),
      routerConfig: GoRouter(
        routes: [GoRoute(path: '/', builder: (context, state) => body)],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 18, bottom: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 10.5,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    ),
  );
}

/// Stands in for HeroActionButton, which needs providers this sheet has not.
class _ScanStandIn extends StatelessWidget {
  const _ScanStandIn();

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.82)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Icon(LucideIcons.scan, color: Colors.white, size: 26),
  );
}
