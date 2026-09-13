import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/core/services/security_service.dart';
import 'package:snapcal/core/services/session_data_guard.dart';
import 'package:snapcal/core/services/session_cleanup_service.dart';
import 'package:snapcal/data/models/water_log.dart';
import 'package:snapcal/data/repositories/water_repository.dart';
import 'package:snapcal/data/repositories/assistant_repository.dart';
import 'package:snapcal/data/services/premium_gate_service.dart';
import 'package:snapcal/data/services/pro_feature_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    Hive.init(
      (await Directory.systemTemp.createTemp('snapcal_lifecycle_')).path,
    );
    Hive.registerAdapter(WaterLogAdapter());
  });
  tearDownAll(Hive.close);

  test(
    'CTA tracking and quota reads are safe before gate initialization',
    () async {
      final gate = PremiumGateService()..resetForTesting();
      expect(gate.getAiMessagesUsed(), 0);
      await gate.recordCtaClicked('cold_start');
      await gate.recordPopupClosed();
    },
  );

  test(
    'key rotation creates and persists a genuinely new encryption key',
    () async {
      final service = SecurityService();
      final previous = await service.getEncryptionKey();
      await service.clearKeys();
      final next = await service.getEncryptionKey();
      expect(next, isNot(orderedEquals(previous)));
      expect(
        await const FlutterSecureStorage().read(key: 'hive_encryption_key'),
        isNotNull,
      );
      expect(await service.getEncryptionKey(), orderedEquals(next));
    },
  );

  test(
    'singletons reopen closed boxes without restarting the process',
    () async {
      final water = WaterRepository();
      final assistant = AssistantRepository();
      await water.init();
      await assistant.init();
      await Hive.box<WaterLog>('water_box').close();
      await Hive.box('assistant_box').close();
      await water.init();
      await assistant.init();
      expect(water.getTotalWater('2026-09-13'), 0);
      await assistant.saveCoachChat([
        {'type': 'user', 'content': 'New session'},
      ]);
      expect(assistant.getCoachChat().single['content'], 'New session');
    },
  );

  test('free history includes today and 13 previous calendar dates', () {
    final now = DateTime(2026, 9, 13, 23, 59);
    bool free(String date) =>
        ProFeatureService.canViewHistoryDate(date, isPro: false, now: now);
    expect(free('2026-09-13'), isTrue);
    expect(free('2026-09-12'), isTrue);
    expect(free('2026-08-31'), isTrue);
    expect(free('2026-08-30'), isFalse);
    expect(free('2026-09-14'), isFalse);
    expect(free('invalid'), isFalse);
    expect(
      ProFeatureService.canViewHistoryDate('2020-01-01', isPro: true, now: now),
      isTrue,
    );
  });

  test(
    'stale UID and same-UID re-login leases cannot apply local writes',
    () async {
      final guard = SessionDataGuard();
      var uid = 'A';
      final original = guard.capture(() => uid);
      uid = 'B';
      expect(original.check, throwsA(isA<StaleSessionException>()));
      uid = 'A';
      await guard.cleanup(() async {});
      await expectLater(
        original.write(() async => fail('stale write')),
        throwsA(isA<StaleSessionException>()),
      );
      expect(guard.capture(() => uid).isCurrent, isTrue);
    },
  );

  test(
    'cleanup drains an applying write, then clears it; queued stale writes fail',
    () async {
      final guard = SessionDataGuard();
      final lease = guard.capture(() => 'A');
      final entered = Completer<void>();
      final release = Completer<void>();
      final records = <String>[];
      final applying = lease.write(() async {
        entered.complete();
        await release.future;
        records.add('old data');
      });
      await entered.future;
      final cleaning = guard.cleanup(() async => records.clear());
      final rejected = expectLater(
        lease.write(() async => records.add('stale')),
        throwsA(isA<StaleSessionException>()),
      );
      release.complete();
      await Future.wait([applying, cleaning, rejected]);
      expect(records, isEmpty);
    },
  );
  test(
    'account deletion cleanup stays suspended through sign-out and repositories reopen',
    () async {
      final assistant = AssistantRepository();
      final water = WaterRepository();
      await assistant.init();
      await water.init();
      await assistant.saveCoachChat([
        {'type': 'user', 'content': 'Private old chat'},
      ]);
      var finished = false;
      await SessionCleanupService().clearLocalUserData(
        wipeSecurityKeys: true,
        finishSession: () async {
          expect(
            SessionDataGuard.instance.capture(() => 'old').isCurrent,
            isFalse,
          );
          finished = true;
        },
      );
      expect(finished, isTrue);
      await assistant.init();
      await water.init();
      expect(assistant.getCoachChat(), isEmpty);
      expect(water.getTotalWater('2026-09-13'), 0);
      expect(
        await const FlutterSecureStorage().read(key: 'hive_encryption_key'),
        isNotNull,
      );
    },
  );
}
