import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/services/connectivity_service.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/providers/meal_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/snap/snap_controller.dart';
import 'package:snapcal/screens/snap/snap_screen.dart';
import 'package:snapcal/screens/snap/widgets/result_modal.dart';

class _Controller extends SnapController {
  _Controller({this.analyzing = false, this.capturing = false, this.problem});
  bool analyzing;
  bool capturing;
  final CameraProblem? problem;
  int cancellations = 0;
  int initializations = 0;
  @override
  bool get isAnalyzing => analyzing;
  @override
  bool get isCapturing => capturing;
  @override
  CameraProblem? get cameraProblem => problem;
  @override
  Future<void> initializeCamera() async => initializations++;
  @override
  List<NutritionResult> get analysisResults => [
    NutritionResult(
      foodName: 'Rice',
      portion: '150g',
      calories: 160,
      protein: 4,
      carbs: 35,
      fat: 1,
    ),
    NutritionResult(
      foodName: 'Chicken',
      portion: '100g',
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 4,
    ),
  ];
  @override
  Future<void> pickFromGallery({
    required MealLog mealProvider,
    required UserSettings settingsProvider,
    required bool isPro,
    required ConnectivityService connectivity,
    required VoidCallback onShowPaywall,
    required VoidCallback onShowResult,
    required void Function(ScanProblem) onProblem,
  }) async => onShowResult();
  @override
  void cancelScan() {
    cancellations++;
    analyzing = false;
    capturing = false;
    super.cancelScan();
  }
}

class _Settings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();
}

class _Meals extends MealLog {
  var pending = Completer<void>();
  final attempts = <List<Meal>>[];
  @override
  Future<void> addMeals(List<Meal> meals) {
    attempts.add(meals);
    return pending.future;
  }
}

Future<GoRouter> _open(
  WidgetTester tester,
  _Controller controller, {
  _Meals? meals,
  Size size = const Size(390, 844),
  SnapInitialMode initialMode = SnapInitialMode.food,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: '/snap',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
      ShellRoute(
        builder: (_, _, child) => child,
        routes: [
          GoRoute(
            path: '/snap',
            builder:
                (_, _) => SnapScreen(
                  controller: controller,
                  initialMode: initialMode,
                ),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectiveIsProProvider.overrideWith((ref) => true),
        settingsProvider.overrideWith(_Settings.new),
        if (meals != null) mealLogProvider.overrideWith(() => meals),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
  return router;
}

void main() {
  testWidgets('photo camera waits when startup finishes in background', (
    tester,
  ) async {
    final controller = _Controller();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    final router = await _open(tester, controller);
    expect(controller.initializations, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(controller.initializations, 1);

    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });

  testWidgets('backgrounding cancels an in-flight photo capture', (
    tester,
  ) async {
    final controller = _Controller(capturing: true);
    final router = await _open(tester, controller);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(controller.cancellations, 1);
    expect(controller.isCapturing, isFalse);

    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });

  testWidgets('barcode launch mode survives startup finishing in background', (
    tester,
  ) async {
    final controller = _Controller();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    final router = await _open(
      tester,
      controller,
      initialMode: SnapInitialMode.barcode,
    );
    expect(controller.isScanningBarcode, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(controller.isScanningBarcode, isTrue);
    expect(controller.initializations, 0);

    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });

  testWidgets(
    'scan stays open on failed batch save and goes home only after successful retry',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => ['none'],
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null,
      );
      final meals = _Meals();
      final router = await _open(tester, _Controller(), meals: meals);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(SnapScreen)))!;
      await tester.tap(find.text(l10n.snap_gallery));
      await tester.pumpAndSettle();
      expect(find.byType(ResultModal), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('result-save-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(meals.attempts.single.length, 2);
      expect(router.routeInformationProvider.value.uri.path, '/snap');
      expect(find.byType(ResultModal), findsOneWidget);
      meals.pending.completeError(StateError('disk full'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultModal), findsOneWidget);
      meals.pending = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('result-save-button')));
      await tester.pump();
      expect(meals.attempts.length, 2);
      meals.pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(ResultModal), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    },
  );
  for (final systemBack in [false, true]) {
    testWidgets(
      '${systemBack ? "system back" : "close"} cancels analysis on the first nested route',
      (tester) async {
        final controller = _Controller(analyzing: true);
        final router = await _open(tester, controller);
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(
            find.byKey(const ValueKey('analyzing-close-button')),
          );
        }
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
        expect(controller.cancellations, greaterThan(0));
        expect(controller.isAnalyzing, isFalse);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
      },
    );
  }
  for (final problem in CameraProblem.values) {
    testWidgets(
      'gallery and manual entry remain available with ${problem.name} camera',
      (tester) async {
        final router = await _open(
          tester,
          _Controller(problem: problem),
          size: const Size(320, 568),
        );
        final l10n =
            AppLocalizations.of(tester.element(find.byType(SnapScreen)))!;
        expect(find.text(l10n.snap_gallery), findsOneWidget);
        expect(find.text(l10n.log_add_manually), findsOneWidget);
        await tester.tap(find.text(l10n.log_add_manually));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        router.dispose();
      },
    );
  }
}
