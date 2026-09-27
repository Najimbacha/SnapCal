import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/theme/app_theme.dart';
import 'package:snapcal/widgets/app_text_field.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.lightTheme,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
);

BoxDecoration _glowBox(WidgetTester tester) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: find.byType(AppTextField),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as BoxDecoration;

void main() {
  testWidgets('shows its label above, its unit inside, and glows while '
      'typed in', (tester) async {
    await tester.pumpWidget(
      _host(
        const AppTextField(
          fieldKey: ValueKey('kcal'),
          label: 'Calories',
          hint: '0',
          unit: 'kcal',
        ),
      ),
    );
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('kcal'), findsOneWidget);
    // The label sits above the box.
    expect(
      tester.getBottomLeft(find.text('Calories')).dy,
      lessThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
    expect(_glowBox(tester).boxShadow, isEmpty);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(_glowBox(tester).boxShadow, hasLength(1));
  });

  testWidgets('a mistake shows under the box with a red edge', (tester) async {
    await tester.pumpWidget(
      _host(
        const AppTextField(
          label: 'Weight',
          unit: 'kg',
          errorText: 'Enter a weight between 20 and 400 kg.',
        ),
      ),
    );
    final message = find.text('Enter a weight between 20 and 400 kg.');
    expect(message, findsOneWidget);
    expect(
      tester.getTopLeft(message).dy,
      greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
    );
    final border =
        tester
                .widget<TextField>(find.byType(TextField))
                .decoration!
                .enabledBorder!
            as OutlineInputBorder;
    expect(border.borderSide.color, AppTheme.lightTheme.colorScheme.error);
  });

  testWidgets('a validator message on a form shows under the box', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      _host(
        Form(
          key: form,
          child: AppTextField(
            hint: 'Email',
            validator: (v) => (v ?? '').contains('@') ? null : 'Enter an email',
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Enter an email'), findsOneWidget);
  });

  testWidgets('fields nobody styled by hand get the same box in both themes', (
    tester,
  ) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(_host(const TextField(), theme: theme));
      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(
        (Theme.of(
                  tester.element(find.byType(TextField)),
                ).inputDecorationTheme.enabledBorder
                as OutlineInputBorder)
            .borderRadius,
        BorderRadius.circular(14),
      );
      expect(decorator.decoration.filled, isTrue);
    }
  });
}
