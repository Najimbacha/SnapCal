import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/services/scan_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ScanGateService gate;
  late SharedPreferences prefs;
  late String? uid;
  late DateTime now;
  Map<String, dynamic> quota(int remaining, {int bonus = 0}) => {
    'monthlyScanLimit': 15,
    'bonusScans': bonus,
    'scanAllowance': 15 + bonus,
    'scansRemaining': remaining,
  };
  Future<void> sync(int remaining, {int bonus = 0}) => gate.syncQuotaFromServer(
    quota(remaining, bonus: bonus),
    gate.beginServerRefresh(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    uid = 'user-a';
    now = DateTime.utc(2026, 9, 20);
    gate = ScanGateService.forTesting(
      preferences: prefs,
      scope: () => uid,
      now: () => now,
    );
  });
  tearDown(() => gate.changes.dispose());

  test('unknown count never masquerades as 15 confirmed scans', () {
    expect(gate.verifiedRemaining, isNull);
    expect(gate.canScan(false), isTrue);
  });

  test(
    'server balance replaces stale count and includes bonus only once',
    () async {
      await prefs.setInt('user-a:scanCount_2026-09', 15);
      await sync(16, bonus: 2);
      expect(gate.verifiedRemaining, 16);
      expect(gate.getMonthlyLimit(), 17);
      expect(gate.getPeriodScanCount(), 1);
      expect(gate.canScan(false), isTrue);
    },
  );

  test('repeated cached scan balance does not deduct another scan', () async {
    await sync(14);
    gate.invalidateServerCount();
    expect(gate.verifiedRemaining, isNull);
    await sync(14);
    await sync(14);
    expect(gate.verifiedRemaining, 14);
    expect(gate.getPeriodScanCount(), 1);
  });

  test(
    'late response from before a scan cannot overwrite newer balance',
    () async {
      final beforeScan = gate.beginServerRefresh();
      gate.invalidateServerCount();
      await sync(13);
      await gate.syncQuotaFromServer(quota(15), beforeScan);
      expect(gate.verifiedRemaining, 13);
    },
  );

  test('out-of-order refresh is ignored', () async {
    final first = gate.beginServerRefresh();
    final second = gate.beginServerRefresh();
    await gate.syncQuotaFromServer(quota(12), second);
    await gate.syncQuotaFromServer(quota(14), first);
    expect(gate.verifiedRemaining, 12);
  });

  test('late account response cannot leak into a different account', () async {
    final first = gate.beginServerRefresh();
    uid = 'user-b';
    await gate.syncQuotaFromServer(quota(3), first);
    expect(gate.verifiedRemaining, isNull);
    expect(prefs.getInt('user-b:scanCount_2026-09'), isNull);
    await sync(15);
    expect(gate.verifiedRemaining, 15);
    uid = 'user-a';
    expect(gate.verifiedRemaining, isNull);
  });

  test(
    'new UTC month hides previous balance and rejects late response',
    () async {
      await sync(0);
      expect(gate.canScan(false), isFalse);
      expect(gate.canScan(true), isTrue);
      final old = gate.beginServerRefresh();
      now = DateTime.utc(2026, 10, 1);
      await gate.syncQuotaFromServer(quota(0), old);
      expect(gate.verifiedRemaining, isNull);
      expect(gate.canScan(false), isTrue);
      await sync(15);
      expect(gate.verifiedRemaining, 15);
    },
  );

  test('null or malformed balances are not treated as full or empty', () async {
    for (final invalid in [null, -1, 16, 2.5, '14', double.nan]) {
      await gate.syncQuotaFromServer({
        ...quota(15),
        'scansRemaining': invalid,
      }, gate.beginServerRefresh());
      expect(gate.verifiedRemaining, isNull);
    }
    await gate.syncQuotaFromServer({
      ...quota(15),
      'scanAllowance': 'broken',
    }, gate.beginServerRefresh());
    expect(gate.verifiedRemaining, isNull);
  });

  test(
    'refresh uses server balance; network failure does not throw or invent quota',
    () async {
      final client = Dio();
      var fail = false;
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, endsWith('/api/premium-status'));
            if (fail) {
              handler.reject(DioException(requestOptions: options));
            } else {
              handler.resolve(
                Response(requestOptions: options, data: quota(14)),
              );
            }
          },
        ),
      );
      await gate.refreshFromServer(client: client);
      expect(gate.verifiedRemaining, 14);
      gate.invalidateServerCount();
      fail = true;
      await gate.refreshFromServer(client: client);
      expect(gate.verifiedRemaining, isNull);
      expect(gate.isRefreshing, isFalse);
      client.close();
    },
  );

  test('logout invalidates in-flight quota response', () async {
    await sync(7);
    final old = gate.beginServerRefresh();
    await gate.resetSessionState();
    await gate.syncQuotaFromServer(quota(7), old);
    expect(gate.verifiedRemaining, isNull);
    expect(prefs.getInt('user-a:scanCount_2026-09'), isNull);
  });
}
