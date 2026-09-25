import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/data/models/body_metric.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/providers/metrics_provider.dart';
import 'package:snapcal/providers/settings_provider.dart';

class _FakeSettings extends Settings {
  @override
  Future<UserSettings> build() async =>
      UserSettings.defaults().copyWith(startingWeight: 72.5);
}

// The capture screen called `logProgressPhoto`, which checked the free-tier
// limit and returned: both photos were dropped and the Progress screen never
// had a check-in to show.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const boxName = 'body_metrics_box';

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.init((await Directory.systemTemp.createTemp('snapcal_photos_')).path);
    Hive.registerAdapter(BodyMetricAdapter());
  });
  tearDownAll(Hive.close);

  setUp(() async {
    if (Hive.isBoxOpen(boxName)) await Hive.box<BodyMetric>(boxName).clear();
  });

  ProviderContainer container({bool isPro = false}) {
    final c = ProviderContainer(
      overrides: [
        effectiveIsProProvider.overrideWithValue(isPro),
        settingsProvider.overrideWith(_FakeSettings.new),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a check-in is saved with both photos and the last known weight', () async {
    final c = container();
    await c.read(bodyMetricsProvider.future);
    await c
        .read(bodyMetricsProvider.notifier)
        .logProgressPhotos(frontPath: '/photos/front.jpg', sidePath: '/photos/side.jpg');

    final metrics = await c.read(bodyMetricsProvider.future);
    expect(metrics, hasLength(1));
    expect(metrics.single.photoFrontPath, '/photos/front.jpg');
    expect(metrics.single.photoSidePath, '/photos/side.jpg');
    // No weigh-in yet, so the onboarding weight carries forward rather than 0.
    expect(metrics.single.weight, 72.5);
  });

  test('photos join the day\'s existing weigh-in', () async {
    final c = container();
    await c.read(bodyMetricsProvider.future);
    final notifier = c.read(bodyMetricsProvider.notifier);
    await notifier.logWeight(80);
    await notifier.logProgressPhotos(frontPath: '/photos/front.jpg');

    final metrics = await c.read(bodyMetricsProvider.future);
    expect(metrics, hasLength(1));
    expect(metrics.single.weight, 80);
    expect(metrics.single.photoFrontPath, '/photos/front.jpg');
    expect(metrics.single.photoSidePath, isNull);
  });

  test('the free tier stops at three check-ins; Pro does not', () async {
    final free = container();
    await free.read(bodyMetricsProvider.future);
    // Three earlier check-ins, written straight into the provider's box.
    final box = Hive.box<BodyMetric>(boxName);
    for (var i = 1; i <= 3; i++) {
      await box.add(
        BodyMetric(
          date: DateTime(2026, 1, i),
          weight: 70,
          photoFrontPath: '/photos/$i.jpg',
        ),
      );
    }
    await expectLater(
      free
          .read(bodyMetricsProvider.notifier)
          .logProgressPhotos(frontPath: '/photos/4.jpg'),
      throwsStateError,
    );

    final pro = container(isPro: true);
    await pro.read(bodyMetricsProvider.future);
    await pro
        .read(bodyMetricsProvider.notifier)
        .logProgressPhotos(frontPath: '/photos/4.jpg');
    final metrics = await pro.read(bodyMetricsProvider.future);
    expect(metrics.where((m) => m.photoFrontPath != null), hasLength(4));
  });

  test('nothing to save is a no-op', () async {
    final c = container();
    await c.read(bodyMetricsProvider.future);
    await c.read(bodyMetricsProvider.notifier).logProgressPhotos();
    expect(await c.read(bodyMetricsProvider.future), isEmpty);
  });
}
