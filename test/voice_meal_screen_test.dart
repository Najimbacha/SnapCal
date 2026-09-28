import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/theme/app_theme.dart';
import 'package:snapcal/data/services/gemini_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/screens/voice/voice_meal_screen.dart';

/// A microphone the test speaks into.
class FakeVoice implements VoiceInput {
  FakeVoice({this.permission = VoicePermission.granted, this.available = true});

  final VoicePermission permission;
  final bool available;
  int starts = 0;
  int stops = 0;
  void Function(String words, bool isFinal)? _words;
  VoidCallback? _done;
  void Function(bool noSpeech)? _error;

  void say(String words, {bool isFinal = false}) =>
      _words?.call(words, isFinal);
  void finish() => _done?.call();
  void fail({bool noSpeech = true}) => _error?.call(noSpeech);

  @override
  Future<VoicePermission> ensurePermission() async => permission;

  @override
  Future<bool> start({
    required String languageCode,
    required void Function(String words, bool isFinal) onWords,
    required void Function(double level) onLevel,
    required VoidCallback onDone,
    required void Function(bool noSpeech) onError,
  }) async {
    starts++;
    _words = onWords;
    _done = onDone;
    _error = onError;
    return available;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> cancel() async {}
}

final _meal = [
  NutritionResult(
    foodName: 'Eggs',
    portion: '2 large',
    calories: 143,
    protein: 12,
    carbs: 1,
    fat: 10,
  ),
  NutritionResult(
    foodName: 'Toast with butter',
    portion: '1 slice',
    calories: 178,
    protein: 4,
    carbs: 20,
    fat: 9,
  ),
];

Widget _app(Widget home) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

Future<void> _open(
  WidgetTester tester,
  FakeVoice voice, {
  List<String>? heard,
  List<NutritionResult>? meal,
}) async {
  await tester.pumpWidget(
    _app(
      VoiceMealScreen(
        input: voice,
        analyzeMeal: (text, language) async {
          heard?.add(text);
          return meal ?? _meal;
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _settleResult(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('opens already listening, with nothing to tap', (tester) async {
    final voice = FakeVoice();
    await _open(tester, voice);

    expect(voice.starts, 1);
    expect(find.byKey(const ValueKey('voice-status')), findsOneWidget);
    expect(find.text('Listening'), findsOneWidget);
    expect(find.text('Say what you ate…'), findsOneWidget);
    expect(find.byKey(const ValueKey('voice-orb')), findsOneWidget);
    expect(find.text("Wazn does not save your audio."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pause finishes, and the foods appear on the same screen', (
    tester,
  ) async {
    final voice = FakeVoice();
    final heard = <String>[];
    await _open(tester, voice, heard: heard);

    voice.say('Two eggs and toast with butter');
    await tester.pump();
    expect(find.text('eggs'), findsOneWidget);

    // Quiet: the ring fills, then it works the meal out by itself.
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Got it'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await _settleResult(tester);

    expect(heard, ['Two eggs and toast with butter']);
    expect(voice.stops, 1);
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('Toast with butter'), findsOneWidget);
    expect(find.text('321'), findsOneWidget);
    expect(find.byKey(const ValueKey('voice-add')), findsOneWidget);
    expect(find.text('Add to Log'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('talking again stops the ring', (tester) async {
    final voice = FakeVoice();
    final heard = <String>[];
    await _open(tester, voice, heard: heard);

    voice.say('Two eggs');
    await tester.pump(const Duration(milliseconds: 1400));
    voice.say('Two eggs and toast');
    await tester.pump(const Duration(milliseconds: 700));
    expect(heard, isEmpty);
    expect(find.text('Tap when you\'re done'), findsWidgets);
  });

  testWidgets('a tap on the orb finishes straight away', (tester) async {
    final voice = FakeVoice();
    final heard = <String>[];
    await _open(tester, voice, heard: heard);

    voice.say('A banana');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('voice-orb')));
    await _settleResult(tester);

    expect(heard, ['A banana']);
  });

  testWidgets('the recogniser\'s own final words finish too', (tester) async {
    final voice = FakeVoice();
    final heard = <String>[];
    await _open(tester, voice, heard: heard);

    voice.say('Lentil soup', isFinal: true);
    await _settleResult(tester);

    expect(heard, ['Lentil soup']);
  });

  testWidgets('nothing heard says so, and the orb is ready again', (
    tester,
  ) async {
    final voice = FakeVoice();
    await _open(tester, voice);

    voice.fail();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('voice-problem')), findsOneWidget);
    expect(find.text('Tap to speak'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('voice-orb')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(voice.starts, 2);
  });

  testWidgets('no microphone access explains, and blocked offers Settings', (
    tester,
  ) async {
    await _open(tester, FakeVoice(permission: VoicePermission.blocked));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('voice-problem')), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('typing instead works the meal out on Done', (tester) async {
    final voice = FakeVoice();
    final heard = <String>[];
    await _open(tester, voice, heard: heard);

    await tester.tap(find.byKey(const ValueKey('voice-type')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const ValueKey('voice-type-field')),
      'Greek yogurt with honey',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('voice-type-done')));
    await _settleResult(tester);

    expect(heard, ['Greek yogurt with honey']);
    expect(find.byKey(const ValueKey('voice-add')), findsOneWidget);
  });

  testWidgets('tapping the words opens them for editing', (tester) async {
    final voice = FakeVoice();
    await _open(tester, voice);
    voice.say('Two eggs', isFinal: true);
    await _settleResult(tester);

    await tester.tap(find.byKey(const ValueKey('voice-words')));
    await tester.pump(const Duration(milliseconds: 400));

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('voice-type-field')),
    );
    expect(field.controller!.text, 'Two eggs');
  });

  testWidgets('fits a short Android screen with results', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final voice = FakeVoice();
    await _open(tester, voice, meal: [..._meal, ..._meal, ..._meal]);
    voice.say('Two eggs and toast with butter', isFinal: true);
    await _settleResult(tester);

    expect(find.byKey(const ValueKey('voice-add')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('marking the foods in the words', () {
    List<Set<int>> match(String said, List<String> foods) =>
        VoiceMealScreen.matchFoods(said.split(' '), foods);

    test('plurals, numbers and several words', () {
      expect(
        match('2 eggs, toast with butter and a flat white', [
          'Egg',
          'Toast with butter',
          'Flat white',
        ]),
        [
          {0, 1},
          {2, 3, 4},
          {7, 8},
        ],
      );
    });

    test('a food not said in so many words marks nothing', () {
      expect(match('my usual breakfast', ['Oatmeal']), [<int>{}]);
    });

    test('a word is marked for one food only', () {
      expect(match('chicken rice', ['Chicken', 'Chicken rice']), [
        {0},
        {1},
      ]);
    });
  });
}
