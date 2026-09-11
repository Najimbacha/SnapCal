import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/screens/settings/widgets/settings_kit.dart';

void main() {
  test('a decimal typed with a comma or a point is the same number', () {
    expect(parseDecimalInput('70,5'), 70.5);
    expect(parseDecimalInput(' 70.5 '), 70.5);
    expect(parseDecimalInput('72'), 72);
    expect(parseDecimalInput('abc'), isNull);
    expect(parseDecimalInput(''), isNull);
  });

  test('imperial heights include the "ft" the old picker saved', () {
    expect(isImperialHeight('in'), isTrue);
    expect(isImperialHeight('ft'), isTrue);
    expect(isImperialHeight('cm'), isFalse);
    expect(isImperialHeight(null), isFalse);
  });

  test('going past the goal leaves nothing to go', () {
    // Losing weight: 90 -> 80.
    expect(weightLeftToGoal(start: 90, current: 85, target: 80), 5);
    expect(weightLeftToGoal(start: 90, current: 78, target: 80), -2);
    // Gaining weight: 60 -> 65.
    expect(weightLeftToGoal(start: 60, current: 62, target: 65), 3);
    expect(weightLeftToGoal(start: 60, current: 66, target: 65), -1);
  });

  testWidgets('reminder times follow the phone clock', (tester) async {
    String? shown;
    Widget probe(String time, {bool use24h = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(alwaysUse24HourFormat: use24h),
        child: Builder(
          builder: (context) {
            shown = formatReminderTime(context, time);
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpWidget(probe('19:30'));
    expect(shown, '7:30 PM');

    await tester.pumpWidget(probe('19:30', use24h: true));
    expect(shown, '19:30');

    await tester.pumpWidget(probe('not a time'));
    expect(shown, 'not a time');
  });
}
