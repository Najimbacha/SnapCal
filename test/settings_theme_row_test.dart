import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/settings/widgets/settings_kit.dart';

final _picked = <String>[];

class _RecordingSettings extends Settings {
  @override
  Future<UserSettings> build() async => UserSettings.defaults();

  @override
  Future<void> setThemeMode(String mode) async => _picked.add(mode);
}

Widget _host() => ProviderScope(
  overrides: [settingsProvider.overrideWith(_RecordingSettings.new)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: SettingsThemeRow(currentMode: 'system')),
  ),
);

void main() {
  setUp(_picked.clear);

  testWidgets('every part of a theme button counts as a tap, top to bottom', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final track = tester.getRect(find.byType(SettingsThemeRow));
    // The buttons fill the track: a tap on the lower or upper edge of a
    // button used to miss, because only the height of the label was live.
    for (final entry in {'Light': 'light', 'Dark': 'dark'}.entries) {
      final x = tester.getCenter(find.text(entry.key)).dx;
      for (final y in [track.top + 22, track.center.dy, track.bottom - 22]) {
        _picked.clear();
        await tester.tapAt(Offset(x, y));
        await tester.pump();
        expect(_picked, [entry.value], reason: '${entry.key} at y=$y');
      }
    }
  });

  testWidgets('the labels sit in the middle of the track', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final track = tester.getRect(find.byType(SettingsThemeRow));
    final label = tester.getCenter(find.text('System')).dy;
    expect((label - track.center.dy).abs(), lessThan(4));
  });
}
