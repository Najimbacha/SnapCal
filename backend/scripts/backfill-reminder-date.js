#!/usr/bin/env node
/**
 * One-time backfill: seed `lastFoodReminderDate` on existing settings docs.
 *
 * Why this is needed
 * ------------------
 * The reminder fan-out queries
 *
 *   collectionGroup('settings')
 *     .where('foodRemindersEnabled', '==', true)
 *     .where('lastFoodReminderDate', '<', today)
 *
 * and Firestore EXCLUDES documents that do not have the field at all from a
 * range comparison. Every user who existed before this change has no
 * `lastFoodReminderDate`, so without this backfill they would be invisible to
 * the query permanently — silently receiving no reminders, with no error.
 *
 * Usage
 * -----
 *   node scripts/backfill-reminder-date.js --dry-run     # count only, no writes
 *   node scripts/backfill-reminder-date.js               # apply
 *
 * Safe to re-run: documents that already carry the field are skipped.
 * Resumable: pass --start-after=<doc path> from the last logged cursor.
 */

require('dotenv').config();

const fs = require('fs');
const admin = require('firebase-admin');

const DRY_RUN = process.argv.includes('--dry-run');
const startAfterArg = process.argv.find((a) => a.startsWith('--start-after='));
const START_AFTER = startAfterArg ? startAfterArg.split('=')[1] : null;
const PAGE = 400;
const SEED = '1970-01-01';

/// Accepts credentials three ways, in order of convenience:
///
///   1. --key=C:\\path\\to\\service-account.json   (or SERVICE_ACCOUNT_FILE)
///   2. FIREBASE_SERVICE_ACCOUNT   — the raw JSON, as the server uses
///   3. Application Default Credentials (gcloud auth application-default login)
///
/// The project id is read from the key itself, so it never has to be guessed
/// from the environment — which is what "Unable to detect a Project Id" means.
function init() {
  if (admin.apps.length) return;

  const keyArg = process.argv.find((a) => a.startsWith('--key='));
  const keyPath =
    (keyArg && keyArg.slice('--key='.length)) ||
    process.env.SERVICE_ACCOUNT_FILE ||
    null;

  let serviceAccount = null;
  if (keyPath) {
    if (!fs.existsSync(keyPath)) {
      console.error(`Service account file not found: ${keyPath}`);
      process.exit(1);
    }
    serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  }

  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.project_id,
    });
    console.log(`Authenticated as ${serviceAccount.client_email}`);
    console.log(`Project: ${serviceAccount.project_id}`);
    return;
  }

  const projectId =
    process.env.FIREBASE_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT;
  if (!projectId) {
    console.error(
      'No credentials. Pass --key=<path to service account json>, or set\n' +
        'FIREBASE_SERVICE_ACCOUNT, or run `gcloud auth application-default\n' +
        'login` and set FIREBASE_PROJECT_ID=snapcal-ef333.',
    );
    process.exit(1);
  }
  admin.initializeApp({ projectId });
  console.log(`Project: ${projectId} (application default credentials)`);
}

async function main() {
  init();
  const db = admin.firestore();

  let cursor = START_AFTER ? await db.doc(START_AFTER).get() : null;
  let scanned = 0;
  let updated = 0;
  let skipped = 0;

  console.log(
    `Backfill lastFoodReminderDate=${SEED} ${DRY_RUN ? '(DRY RUN)' : '(APPLYING)'}`,
  );

  for (;;) {
    let query = db
      .collectionGroup('settings')
      .orderBy('__name__')
      .limit(PAGE);
    if (cursor) query = query.startAfter(cursor);

    const snap = await query.get();
    if (snap.empty) break;

    const writer = DRY_RUN ? null : db.bulkWriter();

    for (const doc of snap.docs) {
      cursor = doc;
      scanned++;
      if (doc.id !== 'app') continue;

      if (doc.get('lastFoodReminderDate') !== undefined) {
        skipped++;
        continue;
      }

      updated++;
      if (writer) {
        writer.set(doc.ref, { lastFoodReminderDate: SEED }, { merge: true });
      }
    }

    if (writer) await writer.close();

    console.log(
      `  scanned=${scanned} updated=${updated} skipped=${skipped} ` +
        `cursor=${cursor.ref.path}`,
    );

    if (snap.size < PAGE) break;
  }

  console.log(
    `Done. scanned=${scanned} ${DRY_RUN ? 'would update' : 'updated'}=${updated} ` +
      `already-set=${skipped}`,
  );
  process.exit(0);
}

main().catch((err) => {
  console.error('Backfill failed:', err);
  process.exit(1);
});
