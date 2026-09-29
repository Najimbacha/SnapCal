import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android keeps the Wazn background while Flutter surface returns', () {
    for (final path in [
      'android/app/src/main/res/values/styles.xml',
      'android/app/src/main/res/values-night/styles.xml',
    ]) {
      final xml = File(path).readAsStringSync();
      final normalTheme = RegExp(
        r'<style name="NormalTheme"[\s\S]*?</style>',
      ).firstMatch(xml)?.group(0);

      expect(normalTheme, isNotNull, reason: '$path must define NormalTheme');
      expect(
        normalTheme,
        contains(
          '<item name="android:windowBackground">'
          '@color/splash_background</item>',
        ),
        reason:
            '$path must not flash a system white/black background while the '
            'Flutter surface is recreated from Recents',
      );
    }
  });
}
