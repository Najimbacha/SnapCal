import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapcal/core/constants/app_constants.dart';
import 'package:snapcal/core/services/security_service.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failed settings open preserves stored settings and allows retry',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp(
        'settings_preservation_',
      );
      Hive.init(directory.path);
      Hive.registerAdapter(UserSettingsAdapter());
      final key = await SecurityService().getEncryptionKey();
      // A conflicting open handle simulates a storage failure without corrupting data.
      final existing = await Hive.openBox<dynamic>(
        AppConstants.settingsBoxName,
        encryptionCipher: HiveAesCipher(key),
      );
      await existing.put(
        AppConstants.settingsKey,
        UserSettings.defaults().copyWith(
          onboardingComplete: true,
          dailyCalorieGoal: 2345,
        ),
      );
      await existing.flush();
      final file = File(existing.path!);
      final bytes = await file.readAsBytes();
      final repo = SettingsRepository.forTesting(
        FakeFirebaseFirestore(),
        MockFirebaseAuth(),
      );
      final emitted = <UserSettings>[];
      final subscription = repo.settingsStream.listen(emitted.add);
      try {
        await expectLater(repo.init(), throwsA(isA<HiveError>()));
        expect(await file.readAsBytes(), bytes);
        expect(emitted, isEmpty);
        await existing.close();
        await repo.init();
        expect(repo.getSettings().onboardingComplete, isTrue);
        expect(repo.getSettings().dailyCalorieGoal, 2345);
      } finally {
        await subscription.cancel();
        repo.dispose();
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
