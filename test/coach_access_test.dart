import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/repositories/assistant_repository.dart';
import 'package:snapcal/data/services/premium_gate_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/providers/repository_providers.dart';
import 'package:snapcal/providers/settings_provider.dart';
import 'package:snapcal/screens/assistant/assistant_screen.dart';

class _ChatRepository implements AssistantRepository {
  @override
  List<Map<String, String>> getCoachChat() => [
    {
      'type': 'assistant',
      'content': 'Your saved nutrition advice remains readable.',
    },
  ];
  @override
  Future<void> saveCoachChat(List<Map<String, String>> messages) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final gate = PremiumGateService()..resetForTesting();
    await gate.init();
    await gate.incrementAiMessages();
  });

  for (final locale in ['en', 'ar', 'es', 'fr']) {
    for (final size in [const Size(320, 568), const Size(640, 360)]) {
      testWidgets('coach quota preserves replies $locale $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<void> show(ProStatus status, {double keyboard = 0}) async {
          await tester.pumpWidget(
            ProviderScope(
              key: ValueKey(status),
              overrides: [
                proAccessProvider.overrideWith((ref) => ProAccess(status)),
                assistantRepositoryProvider.overrideWith(
                  (ref) async => _ChatRepository(),
                ),
              ],
              child: MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder:
                    (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(2),
                        viewInsets: EdgeInsets.only(bottom: keyboard),
                      ),
                      child: child!,
                    ),
                home: const AssistantScreen(),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
        }

        await show(ProStatus.free);
        expect(
          find.text(
            'Your saved nutrition advice remains readable.',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNothing);
        expect(PremiumGateService().getAiMessagesUsed(), 1);
        expect(tester.takeException(), isNull);

        // Simulate the next quota day without touching the user's stored chat.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_premium_popup_date', '2000-01-01');
        await tester.pump(const Duration(seconds: 31));
        expect(find.byType(TextField), findsOneWidget);
        expect(
          find.text(
            'Your saved nutrition advice remains readable.',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(PremiumGateService().getAiMessagesUsed(), 0);
        expect(tester.takeException(), isNull);

        await show(ProStatus.pro, keyboard: size.height < 400 ? 140 : 250);
        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(
          find.byType(TextField),
          'A longer question about meals and protein goals.',
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
