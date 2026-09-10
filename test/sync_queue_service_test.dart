import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:snapcal/data/services/sync_queue_service.dart';

void main() {
  late SyncQueueService queue;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('snapcal_sync_queue');
    Hive.init(dir.path);
    queue = SyncQueueService();
  });

  setUp(() => queue.clear());
  tearDown(() => queue.clear());

  List<String> dueIds() =>
      queue
          .dueOperations(DateTime.now().millisecondsSinceEpoch)
          .map((entry) => entry.value['id'] as String)
          .toList();

  test('sync queue enqueues idempotent local operations', () async {
    await queue.enqueueSet(
      id: 'settings:set:user-a',
      documentPath: 'users/user-a',
      data: {
        'settings': {'dailyCalorieGoal': 2000},
      },
    );
    await queue.enqueueSet(
      id: 'settings:set:user-a',
      documentPath: 'users/user-a',
      data: {
        'settings': {'dailyCalorieGoal': 2100},
      },
    );

    expect(queue.pendingCount, 1);
  });

  // The bug: keys come back alphabetically, so "meal:delete:..." ran before
  // "meal:set:..." and a meal logged and deleted offline came back.
  test(
    'a queued delete replaces an earlier save of the same document',
    () async {
      const path = 'users/u/meals/m1';
      await queue.enqueueSet(
        id: 'meal:set:u:m1',
        documentPath: path,
        data: {'id': 'm1'},
      );
      await queue.enqueueDelete(id: 'meal:delete:u:m1', documentPath: path);

      expect(dueIds(), ['meal:delete:u:m1']);
    },
  );

  test('a save after a delete (undo) replaces the queued delete', () async {
    const path = 'users/u/meals/m1';
    await queue.enqueueDelete(id: 'meal:delete:u:m1', documentPath: path);
    await queue.enqueueSet(
      id: 'meal:set:u:m1',
      documentPath: path,
      data: {'id': 'm1'},
    );

    expect(dueIds(), ['meal:set:u:m1']);
  });

  test('different documents replay in the order they were changed', () async {
    await queue.enqueueSet(id: 'z:set', documentPath: 'users/u/a/1', data: {});
    await queue.enqueueDelete(id: 'a:delete', documentPath: 'users/u/a/2');
    await queue.enqueueSet(id: 'm:set', documentPath: 'users/u/a/3', data: {});

    expect(dueIds(), ['z:set', 'a:delete', 'm:set']);
  });

  test('reports whether a document has an unsent change', () async {
    await queue.enqueueSet(
      id: 'w:1',
      documentPath: 'users/u/waterLogs/1',
      data: {},
    );

    expect(queue.hasPendingFor('users/u/waterLogs/1'), isTrue);
    expect(queue.hasPendingFor('users/u/waterLogs/2'), isFalse);
  });
}
