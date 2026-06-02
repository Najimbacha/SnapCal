import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:snapcal/data/services/sync_queue_service.dart';

void main() {
  test('sync queue enqueues idempotent local operations', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('snapcal_sync_queue');
    Hive.init(dir.path);

    final queue = SyncQueueService();
    await queue.clear();

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

    await queue.clear();
  });
}
