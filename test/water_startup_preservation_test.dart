import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/repositories/water_repository.dart';

void main() {
  test('storage open failures propagate and remain retryable', () async {
    var attempts = 0;
    final repository = WaterRepository.forTesting(
      loadEncryptionKey: () async => List<int>.filled(32, 1),
      openBox: (_) async {
        attempts++;
        throw StateError('storage temporarily unavailable');
      },
    );
    await expectLater(repository.init(), throwsA(isA<Object>()));
    await expectLater(repository.init(), throwsA(isA<Object>()));

    expect(attempts, 2);
  });
}
