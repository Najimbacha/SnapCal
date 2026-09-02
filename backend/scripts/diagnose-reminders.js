#!/usr/bin/env node
/**
 * Explains why the reminder fan-out found the number of users it found.
 *
 * Reports each filter the production query applies, in order, so a zero is
 * attributable to a specific condition rather than to "something is wrong".
 * Also distinguishes a missing index (FAILED_PRECONDITION) from an empty
 * result, which look identical from the endpoint's response.
 *
 *   node scripts/diagnose-reminders.js --key=<service account json>
 */

require('dotenv').config();

const fs = require('fs');
const admin = require('firebase-admin');

function init() {
  if (admin.apps.length) return;
  const keyArg = process.argv.find((a) => a.startsWith('--key='));
  const keyPath = (keyArg && keyArg.slice('--key='.length)) || process.env.SERVICE_ACCOUNT_FILE;
  let serviceAccount = null;
  if (keyPath) {
    if (!fs.existsSync(keyPath)) {
      console.error(`Service account file not found: ${keyPath}`);
      process.exit(1);
    }
    serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else {
    console.error('Pass --key=<path to service account json>.');
    process.exit(1);
  }
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
  console.log(`Project: ${serviceAccount.project_id}\n`);
}

function todayKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

async function main() {
  init();
  const db = admin.firestore();
  const today = todayKey();
  console.log(`Server date used by the job: ${today}\n`);

  // Full scan, deliberately: this is a diagnostic on a small dataset, not the
  // production path.
  const snap = await db.collectionGroup('settings').get();
  const appDocs = snap.docs.filter((d) => d.id === 'app');

  let remindersOn = 0;
  let hasDateField = 0;
  let dateBeforeToday = 0;
  let notifsNotDisabled = 0;
  let notOpenedToday = 0;
  let hasToken = 0;
  let fullyEligible = 0;

  for (const doc of appDocs) {
    const d = doc.data() || {};
    if (d.foodRemindersEnabled !== true) continue;
    remindersOn++;

    const hasDate = d.lastFoodReminderDate !== undefined;
    if (hasDate) hasDateField++;
    const beforeToday = hasDate && String(d.lastFoodReminderDate) < today;
    if (beforeToday) dateBeforeToday++;

    if (d.notificationsEnabled !== false) notifsNotDisabled++;
    if ((d.lastOpenedDate || '') !== today) notOpenedToday++;
    if (d.fcmToken) hasToken++;

    if (
      beforeToday &&
      d.notificationsEnabled !== false &&
      (d.lastOpenedDate || '') !== today &&
      d.fcmToken
    ) {
      fullyEligible++;
    }
  }

  console.log(`settings/app documents ............. ${appDocs.length}`);
  console.log(`  foodRemindersEnabled === true .... ${remindersOn}`);
  console.log(`  has lastFoodReminderDate ......... ${hasDateField}   <- missing => invisible to the range query`);
  console.log(`  lastFoodReminderDate < today ..... ${dateBeforeToday}`);
  console.log(`  notificationsEnabled !== false ... ${notifsNotDisabled}`);
  console.log(`  did NOT open the app today ....... ${notOpenedToday}   <- opening the app suppresses the reminder`);
  console.log(`  has an fcmToken .................. ${hasToken}`);
  console.log(`  ALL conditions met .............. ${fullyEligible}\n`);

  // Now the production query itself, which is what tells us about the index.
  try {
    const q = await db
      .collectionGroup('settings')
      .where('foodRemindersEnabled', '==', true)
      .where('lastFoodReminderDate', '<', today)
      .orderBy('lastFoodReminderDate')
      .orderBy('__name__')
      .limit(500)
      .get();
    console.log(`Production query returned ${q.size} document(s). Index is working.`);
    if (q.size === 0 && dateBeforeToday > 0) {
      console.log('MISMATCH: the scan found candidates the query did not. Check the index fields.');
    }
  } catch (err) {
    if (String(err.message).includes('FAILED_PRECONDITION') || String(err.code) === '9') {
      console.error('INDEX MISSING OR STILL BUILDING.');
      console.error(err.message);
    } else {
      console.error('Query failed:', err.message);
    }
  }

  process.exit(0);
}

main().catch((err) => {
  console.error('Diagnose failed:', err);
  process.exit(1);
});
