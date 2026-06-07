import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/services/app_prompt_session_coordinator.dart';
import 'package:snapcal/data/services/app_review_service.dart';

class _FakeReviewClient implements AppReviewClient {
  _FakeReviewClient({this.throwOnRequest = false});

  final bool throwOnRequest;
  int requestCount = 0;
  int openStoreCount = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async {
    requestCount++;
    if (throwOnRequest) {
      throw Exception('Review flow failed');
    }
  }

  @override
  Future<void> openStoreListing() async {
    openStoreCount++;
  }
}

Future<AppReviewService> _service({
  required _FakeReviewClient reviewClient,
  DateTime? now,
  String version = '1.0.0+1',
}) async {
  final prefs = await SharedPreferences.getInstance();
  final service = AppReviewService(
    preferences: prefs,
    reviewClient: reviewClient,
    versionProvider: () async => version,
    isAndroid: () => true,
    clock: () => now ?? DateTime(2026, 6, 3),
  );
  await service.init();
  return service;
}

Map<String, Object> _eligibleState({
  int successfulLogCount = 5,
  String lastReviewAttemptDate = '',
  String lastReviewAttemptedVersion = '',
  String automaticTriggerUsedVersion = '',
  String version = '1.0.0+1',
}) {
  return <String, Object>{
    'review_first_use_date': '2026-05-29',
    'review_distinct_usage_days': <String>[
      '2026-05-29',
      '2026-05-30',
      '2026-06-01',
    ],
    'review_successful_log_count': successfulLogCount,
    'review_current_version_first_seen_date_$version': '2026-05-31',
    if (lastReviewAttemptDate.isNotEmpty)
      'review_last_attempt_date': lastReviewAttemptDate,
    if (lastReviewAttemptedVersion.isNotEmpty)
      'review_last_attempted_app_version': lastReviewAttemptedVersion,
    if (automaticTriggerUsedVersion.isNotEmpty)
      'review_automatic_trigger_used_app_version': automaticTriggerUsedVersion,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppPromptSessionCoordinator().resetForTesting();
  });

  test('user with fewer than 5 successful actions is not eligible', () async {
    SharedPreferences.setMockInitialValues(
      _eligibleState(successfulLogCount: 4),
    );
    final client = _FakeReviewClient();
    final service = await _service(reviewClient: client);

    await service.requestReviewIfEligible();

    expect(client.requestCount, 0);
  });

  test(
    'user with enough usage but prompted within 90 days is not eligible',
    () async {
      SharedPreferences.setMockInitialValues(
        _eligibleState(lastReviewAttemptDate: '2026-04-15', version: '1.0.1+2'),
      );
      final client = _FakeReviewClient();
      final service = await _service(reviewClient: client, version: '1.0.1+2');

      await service.requestReviewIfEligible();

      expect(client.requestCount, 0);
    },
  );

  test('user prompted in current app version is not eligible', () async {
    SharedPreferences.setMockInitialValues(
      _eligibleState(lastReviewAttemptedVersion: '1.0.0+1'),
    );
    final client = _FakeReviewClient();
    final service = await _service(reviewClient: client);

    await service.requestReviewIfEligible();

    expect(client.requestCount, 0);
  });

  test('eligible user triggers one request attempt only', () async {
    SharedPreferences.setMockInitialValues(_eligibleState());
    final client = _FakeReviewClient();
    final service = await _service(reviewClient: client);

    await service.requestReviewIfEligible();
    await service.requestReviewIfEligible();

    expect(client.requestCount, 1);
  });

  test('failure from InAppReview never crashes the app', () async {
    SharedPreferences.setMockInitialValues(_eligibleState());
    final client = _FakeReviewClient(throwOnRequest: true);
    final service = await _service(reviewClient: client);

    await service.requestReviewIfEligible();

    expect(client.requestCount, 1);
  });

  test('Settings rate button action opens the store listing method', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final client = _FakeReviewClient();
    final service = await _service(reviewClient: client);

    await service.openStoreRatingPage();

    expect(client.openStoreCount, 1);
    expect(client.requestCount, 0);
  });

  test(
    'review prompt is skipped after promotional paywall in same session',
    () async {
      SharedPreferences.setMockInitialValues(_eligibleState());
      final client = _FakeReviewClient();
      final service = await _service(reviewClient: client);
      AppPromptSessionCoordinator().markPromotionalPaywallShown();

      await service.requestReviewIfEligible();

      expect(client.requestCount, 0);
    },
  );
}
