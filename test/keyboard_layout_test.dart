import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapcal/core/theme/app_theme.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/auth/auth_screen.dart';
import 'package:snapcal/screens/log/widgets/custom_food_sheet.dart';
import 'package:snapcal/screens/voice/voice_meal_screen.dart';
import 'package:snapcal/widgets/wazn_icons.dart';

/// A small Android phone with the keyboard up: 360 x 640, keyboard 280 tall.
const _width = 360.0, _height = 640.0, _keyboard = 280.0;

void _smallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(_width, _height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

Future<void> _raiseKeyboard(WidgetTester tester) async {
  tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
  await tester.pumpAndSettle();
}

/// Whether [finder] sits wholly above the keyboard, on screen.
bool _aboveKeyboard(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder);
  return rect.top >= 0 && rect.bottom <= _height - _keyboard + 0.5;
}

Widget _app(Widget home) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

/// A microphone that never hears anything.
class _SilentVoice implements VoiceInput {
  @override
  Future<VoicePermission> ensurePermission() async => VoicePermission.granted;

  @override
  Future<bool> start({
    required String languageCode,
    required void Function(String words, bool isFinal) onWords,
    required void Function(double level) onLevel,
    required VoidCallback onDone,
    required void Function(bool noSpeech) onError,
  }) async => true;

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('your own food keeps Add right above the keyboard', (
    tester,
  ) async {
    _smallPhone(tester);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showCustomFoodSheet(context, mealType: 'Snack'),
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await _raiseKeyboard(tester);

    expect(
      _aboveKeyboard(tester, find.byKey(const ValueKey('custom-food-add'))),
      isTrue,
    );
    expect(
      _aboveKeyboard(tester, find.byKey(const ValueKey('custom-food-name'))),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing a meal keeps Done right above the keyboard', (
    tester,
  ) async {
    _smallPhone(tester);
    await tester.pumpWidget(_app(VoiceMealScreen(input: _SilentVoice())));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('voice-type')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const ValueKey('voice-type-field')),
      'Two eggs and toast',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('voice-orb')), findsNothing);
    expect(
      _aboveKeyboard(tester, find.byKey(const ValueKey('voice-type-done'))),
      isTrue,
    );
    expect(
      _aboveKeyboard(tester, find.byKey(const ValueKey('voice-type-field'))),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-in: Next goes to the password, Log In stays in view', (
    tester,
  ) async {
    _smallPhone(tester);
    await tester.pumpWidget(_app(const AuthScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(WaznIcons.mail).first);
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    TextField field(int i) => tester.widget<TextField>(fields.at(i));
    expect(field(0).textInputAction, TextInputAction.next);
    expect(field(1).textInputAction, TextInputAction.go);

    await tester.tap(fields.at(0));
    await _raiseKeyboard(tester);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(field(1).focusNode!.hasFocus, isTrue);

    expect(_aboveKeyboard(tester, find.text('Log In')), isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
