import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const publicName = 'Wazn';
  // The old name in Latin script, or spelled out in Arabic ("سناب كال").
  final oldBrand = RegExp(
    r'(?<![A-Za-z0-9_])snapcal(?![A-Za-z0-9_])|سناب',
    caseSensitive: false,
  );

  test('translated user-facing copy uses the Wazn brand', () {
    final arbFiles = Directory(
      'lib/l10n',
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.arb'));

    for (final file in arbFiles) {
      final entries =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final entry in entries.entries.where(
        (entry) => !entry.key.startsWith('@'),
      )) {
        expect(
          entry.value.toString(),
          isNot(matches(oldBrand)),
          reason: '${file.path}:${entry.key} still exposes the old brand',
        );
      }
    }

    final english =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    expect(english['appTitle'], publicName);
  });

  test('native app labels and legal pages use the Wazn brand', () {
    final androidManifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final androidWidget =
        File(
          'android/app/src/main/res/layout/widget_layout.xml',
        ).readAsStringSync();
    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();

    expect(androidManifest, contains('android:label="$publicName"'));
    expect(androidWidget, contains('android:text="$publicName"'));
    expect(iosInfo, contains('<string>$publicName</string>'));

    for (final file
        in Directory('backend/legal').listSync().whereType<File>()) {
      expect(
        file.readAsStringSync(),
        isNot(matches(oldBrand)),
        reason: '${file.path} still exposes the old brand',
      );
    }
  });
}
