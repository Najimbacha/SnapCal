import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localized ARB files expose the same user-facing keys', () {
    final arbDir = Directory('lib/l10n');
    final en = _readArb(File('${arbDir.path}/app_en.arb'));
    final expectedKeys =
        en.keys.where((key) => !key.startsWith('@')).toSet()
          ..remove('@@locale');

    for (final locale in ['ar', 'es', 'fr']) {
      final arb = _readArb(File('${arbDir.path}/app_$locale.arb'));
      final keys =
          arb.keys.where((key) => !key.startsWith('@')).toSet()
            ..remove('@@locale');

      expect(
        keys.difference(expectedKeys),
        isEmpty,
        reason: '$locale has extra keys',
      );
      expect(
        expectedKeys.difference(keys),
        isEmpty,
        reason: '$locale is missing keys',
      );
    }
  });

  test('known visible English literals stay out of Dart UI code', () {
    final libDir = Directory('lib');
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) =>
              !file.path.contains(
                '${Platform.pathSeparator}l10n${Platform.pathSeparator}generated${Platform.pathSeparator}',
              ),
        );

    final combinedSource = dartFiles
        .map((file) => _stripIgnoredSource(file.readAsStringSync()))
        .join('\n');
    const forbiddenLiterals = [
      'Launch Encountered an Issue',
      'Retry Launch',
      'Initialization Error',
      'Your journey to a healthier you starts here.',
      'Back to Social Login',
      'Maybe Later',
      'Calories eaten',
      'Saved meal added',
      'Meal name',
      'AI meal insight',
      'ADD NEW ITEM',
      'Weight Trend',
      'Monthly calendar coming soon',
      'No data for this week yet.',
      'Cancel anytime. No commitment.',
    ];

    for (final literal in forbiddenLiterals) {
      expect(combinedSource.contains(literal), isFalse, reason: literal);
    }
  });
}

Map<String, dynamic> _readArb(File file) {
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

String _stripIgnoredSource(String source) {
  return source
      .replaceAll(RegExp(r"debugPrint\([^\n]*\);"), '')
      .replaceAll(RegExp(r'//.*'), '');
}
