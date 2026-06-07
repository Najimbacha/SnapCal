import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:snapcal/data/services/connectivity_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:snapcal/widgets/app_page_scaffold.dart';

void main() {
  testWidgets(
    'scrollable page scaffold does not bottom overflow on short phones',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _app(
          child: AppPageScaffold(
            title: 'Compact',
            scrollable: true,
            bottomBar: const _BottomBar(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(
                14,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 56,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('Row $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('scrollable page scaffold remains safe with text scaling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(
        textScaler: const TextScaler.linear(1.35),
        child: AppPageScaffold(
          title: 'Large Text',
          scrollable: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(
              8,
              (index) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Long setting label that should wrap instead of causing a bottom overflow.',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Widget _app({required Widget child, TextScaler? textScaler}) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (context, state) => child)],
  );

  return ChangeNotifierProvider(
    create: (_) => ConnectivityService(),
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, appChild) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: textScaler ?? TextScaler.noScaling),
          child: appChild!,
        );
      },
    ),
  );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(onPressed: () {}, child: const Text('Continue')),
      ),
    );
  }
}
