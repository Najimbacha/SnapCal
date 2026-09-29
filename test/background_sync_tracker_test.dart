import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/background_sync_tracker.dart';

void main() {
  setUp(BackgroundSyncTracker().resetForTesting);

  test('session exit waits until tracked background writes settle', () async {
    final tracker = BackgroundSyncTracker();
    final write = Completer<void>();
    tracker.track(write.future);

    var finished = false;
    final waiting = tracker.waitForIdle().then((_) => finished = true);
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);

    write.complete();
    await waiting;
    expect(finished, isTrue);
    expect(tracker.pendingCount, 0);
  });

  test('failed background writes block destructive session exit', () async {
    final tracker = BackgroundSyncTracker();
    final write = Completer<void>();
    tracker.track(write.future);

    final waiting = tracker.waitForIdle();
    write.completeError(StateError('offline'));

    await expectLater(waiting, throwsA(isA<BackgroundSyncFailure>()));
    expect(tracker.pendingCount, 0);
    tracker.resetForTesting();
  });

  test('late completion from a discarded session is ignored', () async {
    final tracker = BackgroundSyncTracker();
    final oldWrite = Completer<void>();
    tracker.track(oldWrite.future);

    tracker.discardSessionState();
    oldWrite.completeError(StateError('old account is offline'));
    await Future<void>.delayed(Duration.zero);

    await expectLater(tracker.waitForIdle(), completes);
    expect(tracker.pendingCount, 0);
  });
}
