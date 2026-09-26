import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/widgets/app_toast.dart';
import 'package:snapcal/widgets/async_state_widgets.dart';
import 'package:snapcal/widgets/empty_state_art.dart';
import 'package:snapcal/widgets/ui_blocks.dart';
import 'package:snapcal/widgets/wazn_icons.dart';

Widget _host(Widget child, {bool calm = false}) => MaterialApp(
  home: Builder(
    builder:
        (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: calm),
          child: Scaffold(body: Center(child: child)),
        ),
  ),
);

Future<void> _run(WidgetTester tester, int ms) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a message card rises in, says its piece and goes', (
    tester,
  ) async {
    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            messenger = ScaffoldMessenger.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    showAppToast(
      messenger,
      kind: ToastKind.success,
      title: 'Meal logged successfully!',
      detail: 'Chicken salad bowl',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final title = find.text('Meal logged successfully!');
    final early = tester.getTopLeft(title).dy;
    await _run(tester, 900);
    final settled = tester.getTopLeft(title).dy;
    expect(early, greaterThan(settled), reason: 'it rises into place');
    expect(find.text('Meal logged successfully!'), findsOneWidget);
    expect(find.text('Chicken salad bowl'), findsOneWidget);

    await _run(tester, 4500);
    expect(find.byType(AppToastCard), findsNothing);
  });

  testWidgets('undo closes the card as an action and runs it', (tester) async {
    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            messenger = ScaffoldMessenger.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    var undone = false;
    SnackBarClosedReason? reason;
    showAppToast(
      messenger,
      kind: ToastKind.undo,
      title: 'Meal deleted',
      actionLabel: 'Undo',
      onAction: () => undone = true,
    ).closed.then((r) => reason = r);
    await _run(tester, 1000);
    await tester.tap(find.text('Undo'));
    await _run(tester, 600);
    expect(undone, isTrue);
    expect(reason, SnackBarClosedReason.action);

    // Left alone, it times out rather than acting.
    reason = null;
    showAppToast(
      messenger,
      kind: ToastKind.undo,
      title: 'Meal deleted',
      actionLabel: 'Undo',
    ).closed.then((r) => reason = r);
    await _run(tester, 5000);
    expect(reason, isNot(SnackBarClosedReason.action));
  });

  test('old snack bar colours map to the new kinds', () {
    expect(toastKindFor(const Color(0xFFE11D48)), isA<ToastKind>());
  });

  testWidgets('loading outlines sweep, and hold still with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const AppStatsSkeleton()));
    await tester.pump(const Duration(milliseconds: 200));
    final sweeping = find.descendant(
      of: find.byType(AppStatsSkeleton),
      matching: find.byType(FractionalTranslation),
    );
    expect(sweeping, findsWidgets);

    await tester.pumpWidget(_host(const AppStatsSkeleton(), calm: true));
    await tester.pump(const Duration(milliseconds: 200));
    expect(sweeping, findsNothing);
  });

  testWidgets('an empty page draws its picture and offers one thing to do', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        AppEmptyState(
          icon: WaznIcons.image,
          title: 'No progress photos yet',
          body: 'Take photos to track your journey.',
          actionLabel: 'Take your first photo',
          onAction: () => tapped = true,
        ),
      ),
    );
    await tester.pump();
    await _run(tester, 2000);
    expect(find.byType(EmptyStateArt), findsOneWidget);
    expect(find.text('No progress photos yet'), findsOneWidget);
    await tester.tap(find.text('Take your first photo'));
    expect(tapped, isTrue);
  });
}
