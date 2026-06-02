import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:snapcal/data/services/upload_queue_service.dart';

void main() {
  test('upload queue stores idempotent upload jobs', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('snapcal_upload_queue');
    Hive.init(dir.path);

    final queue = UploadQueueService();
    await queue.clear();

    await queue.enqueueFileUpload(
      id: 'progress-photo:user-a:20260602:front',
      localFilePath: '${dir.path}/front.jpg',
      storagePath: 'users/user-a/progress_photos/20260602-front.jpg',
      metadata: {'kind': 'progress_photo'},
    );
    await queue.enqueueFileUpload(
      id: 'progress-photo:user-a:20260602:front',
      localFilePath: '${dir.path}/front-v2.jpg',
      storagePath: 'users/user-a/progress_photos/20260602-front.jpg',
      metadata: {'kind': 'progress_photo'},
    );

    expect(queue.pendingCount, 1);

    await queue.clear();
  });
}
