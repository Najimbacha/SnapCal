import 'dart:io';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapcal/data/models/meal.dart';
import 'package:snapcal/data/models/user_settings.dart';
import 'package:snapcal/data/repositories/meal_repository.dart';
import 'package:snapcal/data/repositories/settings_repository.dart';
import 'package:snapcal/data/services/cloud_record_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    Hive.init((await Directory.systemTemp.createTemp('snapcal_history_')).path);
    Hive.registerAdapter(MealAdapter());
    Hive.registerAdapter(MacrosAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
  });
  tearDownAll(Hive.close);

  test(
    'backfills legacy history across pages even with an existing 30-day cursor',
    () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'A'),
        signedIn: true,
      );
      final repo = MealRepository.forTesting(db, auth);
      await repo.init();
      await repo.syncFromFirestore();
      final index = Hive.box<List<String>>('meal_index_box');
      await index.delete('mealSyncCursor:AfullHistoryV1');
      final oldDate = DateTime(2020, 1, 1);
      for (var i = 0; i < 205; i++) {
        final meal = Meal(
          id: 'old$i',
          timestamp: oldDate.millisecondsSinceEpoch,
          dateString: '2020-01-01',
          foodName: 'Old meal $i',
          calories: 100,
          macros: Macros(protein: 10, carbs: 10, fat: 2),
        );
        await db.doc('users/A/meals/${meal.id}').set(meal.toJson());
      }
      await repo.syncFromFirestore();
      expect(repo.getMealsByDate('2020-01-01').length, 205);
      expect(index.containsKey('mealSyncCursor:AfullHistoryV1'), isTrue);
      await Hive.box<Meal>('meals_box').close();
      await index.close();
      await repo.init();
      expect(repo.getMealsByDate('2020-01-01').length, 205);
      await repo.syncFromFirestore();
      repo.dispose();
    },
  );

  test(
    'failed meal pull propagates and does not mark backfill complete',
    () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'B'),
        signedIn: true,
      );
      final repo = MealRepository.forTesting(db, auth);
      await repo.init();
      await repo.syncFromFirestore();
      final index = Hive.box<List<String>>('meal_index_box');
      await index.delete('mealSyncCursor:BfullHistoryV1');
      final query = db.doc('users/B/meals/unavailable');
      await query.set({'id': 'unavailable'});
      whenCalling(Invocation.method(#get, null))
          .on(query)
          .thenThrow(
            FirebaseException(plugin: 'firestore', code: 'unavailable'),
          );
      await expectLater(
        repo.syncFromFirestore(),
        throwsA(isA<FirebaseException>()),
      );
      expect(index.containsKey('mealSyncCursor:BfullHistoryV1'), isFalse);
      repo.dispose();
    },
  );

  test(
    'settings pull failures are observable by the sync coordinator',
    () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'C'),
        signedIn: true,
      );
      final repo = SettingsRepository.forTesting(db, auth);
      await repo.init();
      await repo.syncFromFirestore(force: true);
      whenCalling(Invocation.method(#get, null))
          .on(db.doc('users/C/settings/app'))
          .thenThrow(
            FirebaseException(plugin: 'firestore', code: 'permission-denied'),
          );
      await expectLater(
        repo.syncFromFirestore(force: true),
        throwsA(isA<FirebaseException>()),
      );
      repo.dispose();
    },
  );

  test(
    'account change inside one applied record prevents subsequent records and cursor writes',
    () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'D'),
        signedIn: true,
      );
      await db.doc('users/D/records/a').set({'updatedAt': 1, 'value': 1});
      await db.doc('users/D/records/b').set({'updatedAt': 2, 'value': 2});
      final sync = CloudRecordSync('records', firestore: db, auth: auth);
      var calls = 0;
      await expectLater(
        sync.pull(
          upsert: (id, data) async {
            calls++;
            await auth.signOut();
            return true;
          },
          delete: (_) async => false,
        ),
        throwsA(isA<Exception>()),
      );
      expect(calls, 1);
      expect(await SyncCursorStore.get('D', 'records'), isNull);
    },
  );
}
