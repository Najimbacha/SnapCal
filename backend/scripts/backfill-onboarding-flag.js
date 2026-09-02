#!/usr/bin/env node
/**
 * One-time backfill: set `onboardingComplete` for users who evidently finished
 * onboarding but whose flag never reached the cloud.
 *
 * Why this is needed
 * ------------------
 * Cloud settings sync was failing closed for every user: `validAppSettings()`
 * in firestore.rules listed fewer fields than SettingsRepository actually
 * writes, and `hasOnly()` evaluates the MERGED document, so one unlisted key
 * rejected the entire write. The client caught the error, queued it, and
 * eventually dropped it. Silent.
 *
 * `onboardingComplete` lives in that payload. In the 2026-09-02 backup, 464
 * users had a private/profile document containing real goals — age, height,
 * daily calorie target — and only 83 carried the flag. 466 people completed
 * onboarding as far as the app is concerned, while Firestore says they never
 * did.
 *
 * That matters on reinstall. A device with empty local storage reads the flag
 * from the cloud, sees false, and walks the user through onboarding again,
 * asking for details they already gave. The rules are fixed now, so it
 * self-heals for anyone who changes a setting — but anyone who reinstalls
 * before that is stuck, and they are the users least likely to come back.
 *
 * What counts as evidence
 * -----------------------
 * A profile document with at least one substantive field (dailyCalorieGoal,
 * targetWeight, age, height), or at least one saved meal. Both are things the
 * app cannot produce without the user going through onboarding. Users with
 * neither are left alone: they really are new.
 *
 * Usage
 * -----
 *   node scripts/backfill-onboarding-flag.js --dry-run --key=<path>
 *   node scripts/backfill-onboarding-flag.js           --key=<path>
 *
 * Safe to re-run: anyone already flagged is skipped.
 */

require('dotenv').config();

const fs = require('fs');
const admin = require('firebase-admin');

const DRY_RUN = process.argv.includes('--dry-run');
const arg = (name) => {
  const found = process.argv.find((a) => a.startsWith(`--${name}=`));
  return found ? found.slice(name.length + 3) : null;
};

const GOAL_FIELDS = ['dailyCalorieGoal', 'targetWeight', 'age', 'height'];

function init() {
  if (admin.apps.length) return;
  const keyPath = arg('key') || process.env.SERVICE_ACCOUNT_FILE;

  if (keyPath) {
    if (!fs.existsSync(keyPath)) {
      console.error(`Service account file not found: ${keyPath}`);
      process.exit(1);
    }
    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
    console.log(`Project: ${serviceAccount.project_id}`);
    return;
  }
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
    console.log(`Project: ${serviceAccount.project_id}`);
    return;
  }
  console.error('No credentials. Pass --key=<path to service account json>.');
  process.exit(1);
}

async function main() {
  init();
  const db = admin.firestore();

  // listDocuments(), not a collection query: Firestore lets a document be
  // missing while its subcollections exist, and on this project 251 of 677
  // users have no `users/{uid}` root document at all. A query would silently
  // skip them.
  const userRefs = await db.collection('users').listDocuments();
  console.log(
    `Found ${userRefs.length} user document ids ${DRY_RUN ? '(DRY RUN)' : '(APPLYING)'}\n`,
  );

  let scanned = 0;
  let alreadySet = 0;
  let noEvidence = 0;
  let updated = 0;
  let writer = DRY_RUN ? null : db.bulkWriter();

  for (const ref of userRefs) {
    scanned++;

    const settingsRef = ref.collection('settings').doc('app');
    const [settingsSnap, profileSnap] = await Promise.all([
      settingsRef.get(),
      ref.collection('private').doc('profile').get(),
    ]);

    if (settingsSnap.exists && settingsSnap.get('onboardingComplete') === true) {
      alreadySet++;
      continue;
    }

    const profile = profileSnap.exists ? profileSnap.data() : {};
    let evidence = GOAL_FIELDS.some((f) => profile[f]);

    // Only pay for the meal lookup when the profile alone is not convincing.
    if (!evidence) {
      const meal = await ref.collection('meals').limit(1).get();
      evidence = !meal.empty;
    }

    if (!evidence) {
      noEvidence++;
      continue;
    }

    updated++;
    if (writer) {
      // merge:true, and only this field. Everything else on the document
      // belongs to the client and must not be touched by a migration.
      writer.set(settingsRef, { onboardingComplete: true }, { merge: true });
    }

    if (updated % 50 === 0) {
      console.log(`  ${scanned}/${userRefs.length} scanned, ${updated} to update`);
    }
  }

  if (writer) await writer.close();

  console.log(
    `\nDone. scanned=${scanned} ${DRY_RUN ? 'would update' : 'updated'}=${updated} ` +
      `already-set=${alreadySet} genuinely-new=${noEvidence}`,
  );
  process.exit(0);
}

main().catch((err) => {
  console.error('Backfill failed:', err);
  process.exit(1);
});
