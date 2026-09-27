import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/theme/app_button_theme.dart';
import 'package:snapcal/core/theme/app_theme.dart';
import 'package:snapcal/widgets/app_button.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.lightTheme,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
);

Color? _fill(WidgetTester tester, {Set<WidgetState> states = const {}}) =>
    tester
        .widget<FilledButton>(find.byType(FilledButton))
        .style!
        .backgroundColor!
        .resolve(states);

void main() {
  testWidgets('the main button is full width, 52 tall, in the app green', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(AppButton(label: 'Save', onPressed: () => taps++)),
    );
    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, appButtonHeight);
    expect(size.width, 800 - 40);
    expect(_fill(tester), AppTheme.lightTheme.colorScheme.primary);

    await tester.tap(find.text('Save'));
    expect(taps, 1);
  });

  testWidgets('not ready yet reads as warm grey, not faded green', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const AppButton(label: 'Add to Lunch', onPressed: null)),
    );
    expect(
      _fill(tester, states: {WidgetState.disabled}),
      AppButtonColors.light.off,
    );
  });

  testWidgets('while busy it keeps its colour and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(AppButton(label: 'Save', loading: true, onPressed: () => taps++)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
    expect(_fill(tester), AppTheme.lightTheme.colorScheme.primary);
  });

  testWidgets('it shrinks a touch while pressed', (tester) async {
    await tester.pumpWidget(_host(AppButton(label: 'Save', onPressed: () {})));
    double scale() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    expect(scale(), 1);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    expect(scale(), lessThan(1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });

  testWidgets('every plain button in the app starts from the same shape', (
    tester,
  ) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        _host(
          FilledButton(onPressed: () {}, child: const Text('Go')),
          theme: theme,
        ),
      );
      // The app eases from one theme to the next.
      await tester.pumpAndSettle();
      final style =
          Theme.of(
            tester.element(find.byType(FilledButton)),
          ).filledButtonTheme.style!;
      expect(
        (style.shape!.resolve({}) as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(appButtonRadius),
      );
      expect(tester.getSize(find.byType(FilledButton)).height, appButtonHeight);
      expect(style.backgroundColor!.resolve({}), theme.colorScheme.primary);
    }
  });
}
