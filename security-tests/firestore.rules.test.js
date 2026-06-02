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
  };

  await assertSucceeds(setDoc(doc(alice, 'users/alice/meals/meal1'), meal));
  await assertFails(setDoc(doc(alice, 'users/bob/meals/meal1'), meal));
  await assertFails(setDoc(doc(alice, 'users/alice/meals/meal2'), { ...meal, id: 'meal1' }));
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
