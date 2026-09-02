import { readFileSync } from 'node:fs';
import assert from 'node:assert';
import test from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'snapcal-security-test';
let env;

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

test.after(async () => {
  await env.cleanup();
});

test.beforeEach(async () => {
  await env.clearFirestore();
});

function dbFor(uid, claims = {}) {
  return env.authenticatedContext(uid, claims).firestore();
}

test('signed out users cannot read profiles', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/alice'), { displayName: 'Alice' });
  });

  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice')));
});

test('owners can read their own profile and cannot read another user profile', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/alice'), { displayName: 'Alice' });
    await setDoc(doc(context.firestore(), 'users/bob'), { displayName: 'Bob' });
  });

  await assertSucceeds(getDoc(doc(dbFor('alice'), 'users/alice')));
  await assertFails(getDoc(doc(dbFor('alice'), 'users/bob')));
});

test('users cannot write trusted subscription, usage, admin, or audit records', async () => {
  const alice = dbFor('alice');
  await assertFails(setDoc(doc(alice, 'users/alice/subscription/current'), { isActive: true }));
  await assertFails(setDoc(doc(alice, 'users/alice/usage/currentMonth'), { scansUsed: 0 }));
  await assertFails(setDoc(doc(alice, 'adminUsers/alice'), { internal: true }));
  await assertFails(setDoc(doc(alice, 'auditLogs/log1'), { actorUid: 'alice' }));
});

test('users cannot create or update trusted scan result fields', async () => {
  const alice = dbFor('alice');
  await assertFails(setDoc(doc(alice, 'users/alice/foodScans/scan12345'), {
    storagePath: 'users/alice/scans/scan12345/scan.jpg',
    createdAt: Date.now(),
    inputSource: 'camera',
    serverCalories: 100,
  }));

  await assertSucceeds(setDoc(doc(alice, 'users/alice/foodScans/scan12345'), {
    storagePath: 'users/alice/scans/scan12345/scan.jpg',
    createdAt: Date.now(),
    inputSource: 'camera',
  }));

  await assertFails(updateDoc(doc(alice, 'users/alice/foodScans/scan12345'), {
    serverNutritionResult: { items: [] },
  }));
});

test('users can write only their own compatible meal records', async () => {
  const alice = dbFor('alice');
  // Mirrors Meal.toJson() (lib/data/models/meal.dart) — include v2 scanner
  // nullable fields so a model change fails this test instead of production.
  const meal = {
    id: 'meal1',
    timestamp: Date.now(),
    dateString: '2026-06-02',
    imageUri: null,
    foodName: 'Rice',
    calories: 200,
    macros: { protein: 4, carbs: 40, fat: 2 },
    synced: true,
    ingredients: null,
    prepTimeMins: null,
    mealType: 'Lunch',
    portion: '1 bowl',
    scanConfidence: null,
    scanSource: 'manual',
    aiRationale: null,
    originalCalories: null,
    userCorrected: true,
    weightG: 120,
    nutritionMatchId: null,
    nutritionPer100g: { calories: 167, protein: 4, carbs: 40, fat: 2 },
  };

  await assertSucceeds(setDoc(doc(alice, 'users/alice/meals/meal1'), meal));
  await assertFails(setDoc(doc(alice, 'users/bob/meals/meal1'), meal));
  await assertFails(setDoc(doc(alice, 'users/alice/meals/meal2'), { ...meal, id: 'meal1' }));
});

test('meal records accept the v2 scanner fields as null or typed', async () => {
  const alice = dbFor('alice');
  const base = {
    id: 'meal3',
    timestamp: Date.now(),
    dateString: '2026-06-02',
    foodName: 'Rice',
    calories: 200,
    macros: { protein: 4, carbs: 40, fat: 2 },
    synced: true,
    userCorrected: false,
    weightG: null,
    nutritionMatchId: null,
    nutritionPer100g: null,
  };
  await assertSucceeds(setDoc(doc(alice, 'users/alice/meals/meal3'), base));

  await assertFails(setDoc(doc(alice, 'users/alice/meals/meal4'), {
    ...base,
    id: 'meal4',
    weightG: 'not-a-number',
  }));
  await assertFails(setDoc(doc(alice, 'users/alice/meals/meal5'), {
    ...base,
    id: 'meal5',
    nutritionPer100g: 'not-a-map',
  }));
});

// Mirrors SettingsRepository._appSettingsPayload() exactly. This test claimed
// to do that before and had drifted: the three `recommendation*` keys were in
// the client payload but not in the rules allowlist, and because hasOnly()
// evaluates the MERGED document, one unlisted key denied the entire write.
// Every settings sync was failing closed, silently, into the retry queue.
// Keep this object byte-for-byte aligned with the Dart payload.
const APP_SETTINGS_PAYLOAD = {
  themeMode: 'system',
  languageCode: 'en',
  onboardingComplete: true,
  notificationsEnabled: true,
  mealRemindersEnabled: true,
  dailyMotivationEnabled: true,
  goalAlertsEnabled: true,
  foodRemindersEnabled: false,
  recommendationInsight: 'Protein is low on weekdays.',
  recommendationTip: 'Add eggs at breakfast.',
  recommendationSafetyNote: null,
  fcmToken: 'fcm:token',
  // Older app versions also send `lastFoodReminderDate` here. It is dead but
  // still allowed, and the tests below prove those writes keep working.
  currentStreak: 12,
  lastLoggedDate: '2026-08-22',
  lastOpenedDate: '2026-08-23',
  breakfastTime: '08:00',
  lunchTime: '12:30',
  dinnerTime: '19:00',
  weightUnit: 'kg',
  heightUnit: 'cm',
  updatedAt: Date.now(),
};

// Mirrors SettingsRepository._profilePayload(). Same drift, same failure mode:
// startingWeight, goalTimelineMonths, weeklyRateKg, foodDislikes and
// medicalNotes were all being written and none were allowlisted.
const PROFILE_PAYLOAD = {
  age: 31,
  height: 178,
  startingWeight: 82.5,
  weight: 82.5,
  targetWeight: 76,
  dailyCalorieGoal: 2100,
  dailyProteinGoal: 150,
  dailyCarbGoal: 200,
  dailyFatGoal: 70,
  gender: 'male',
  activityLevel: 'moderate',
  goalMode: 'lose',
  goalTimelineMonths: 6,
  weeklyRateKg: 0.5,
  dietaryRestriction: 'none',
  cuisinePreference: 'mediterranean',
  foodDislikes: 'olives',
  medicalNotes: null,
  mealsPerDay: 3,
  updatedAt: Date.now(),
};

test('app-settings payload written by SettingsRepository is accepted', async () => {
  const alice = dbFor('alice');
  await assertSucceeds(setDoc(
    doc(alice, 'users/alice/settings/app'),
    APP_SETTINGS_PAYLOAD,
  ));
});

test('profile payload written by SettingsRepository is accepted', async () => {
  const alice = dbFor('alice');
  await assertSucceeds(setDoc(
    doc(alice, 'users/alice/private/profile'),
    PROFILE_PAYLOAD,
  ));
});

test('clients cannot seed the reminder tracking field on create', async () => {
  const alice = dbFor('alice');
  await assertFails(setDoc(doc(alice, 'users/alice/settings/app'), {
    ...APP_SETTINGS_PAYLOAD,
    serverReminderSentOn: '2026-08-20',
  }));
});

test('clients cannot overwrite the reminder date the worker wrote', async () => {
  // The worker records the send through the Admin SDK, which bypasses rules.
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'users/alice/settings/app'),
      { ...APP_SETTINGS_PAYLOAD, serverReminderSentOn: '2026-08-24' },
    );
  });

  const alice = dbFor('alice');

  // The regression: clearing the field re-arms the reminder for the same day.
  await assertFails(updateDoc(doc(alice, 'users/alice/settings/app'), {
    themeMode: 'dark',
    serverReminderSentOn: null,
  }));

  await assertFails(updateDoc(doc(alice, 'users/alice/settings/app'), {
    serverReminderSentOn: '1970-01-01',
  }));

  // Everything else on the document is still the user's to change, and the
  // untouched reminder date must not block an ordinary write.
  await assertSucceeds(updateDoc(doc(alice, 'users/alice/settings/app'), {
    themeMode: 'dark',
  }));
});

// This is the test that buys the independent deploy. An app already on a
// user's phone sends the full legacy payload, `lastFoodReminderDate` included,
// with a null it does not know is meaningless. If that write is rejected, the
// rules cannot be deployed until Play Store adoption is high, and every user
// who has not updated silently loses cloud settings sync in the meantime.
test('an older app version can still write settings after the worker has run', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'users/alice/settings/app'),
      { ...APP_SETTINGS_PAYLOAD, serverReminderSentOn: '2026-08-24' },
    );
  });

  const alice = dbFor('alice');
  const legacyPayload = { ...APP_SETTINGS_PAYLOAD, lastFoodReminderDate: null };

  await assertSucceeds(setDoc(
    doc(alice, 'users/alice/settings/app'),
    legacyPayload,
    { merge: true },
  ));

  // And having written it, the worker's record is still intact.
  const after = await getDoc(doc(alice, 'users/alice/settings/app'));
  assert.strictEqual(after.data().serverReminderSentOn, '2026-08-24');
});

// The incremental meal sync depends on this field reaching Firestore. If the
// allowlist ever loses it, every meal write is rejected, the client falls back
// to its retry queue, and meals stop syncing — while the pull silently reverts
// to reading the full 30-day window on every launch.
test('meals may carry the updatedAt field the incremental sync needs', async () => {
  const alice = dbFor('alice');
  await assertSucceeds(setDoc(doc(alice, 'users/alice/meals/m1'), {
    id: 'm1',
    timestamp: 1756800000000,
    dateString: '2026-09-02',
    foodName: 'Chicken and rice',
    calories: 620,
    macros: { protein: 45, carbs: 60, fat: 18 },
    updatedAt: 1756800500000,
  }));
});

test('admin claim can read audit logs but cannot write them', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'auditLogs/log1'), { action: 'test' });
  });
  const adminDb = dbFor('adminuid', { admin: true });
  await assertSucceeds(getDoc(doc(adminDb, 'auditLogs/log1')));
  await assertFails(setDoc(doc(adminDb, 'auditLogs/log2'), { action: 'test' }));
});

test('unmatched collections are denied', async () => {
  await assertFails(setDoc(doc(dbFor('alice'), 'publicData/doc1'), { ok: true }));
});
