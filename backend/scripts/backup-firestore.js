#!/usr/bin/env node
/**
 * Local Firestore backup — the free-tier substitute for scheduled backups.
 *
 * Why this exists
 * ---------------
 * Firestore's own scheduled backups, PITR and managed exports all require
 * billing to be enabled. On the Spark plan there is no built-in way back from
 * deleted or corrupted data, which is the single worst risk this project
 * carries. Reading every document and writing it to a local JSON file is not
 * as good — it is a point-in-time copy taken by hand, on a laptop, with no
 * retention policy — but it is the difference between losing everything and
 * losing a day.
 *
 * Read quota
 * ----------
 * Every document copied costs one read against the Spark free tier's 50,000
 * per day. The script counts as it goes and stops before it can eat the whole
 * allowance out from under the live app. Run it when the app is quiet.
 *
 * Usage
 * -----
 *   node scripts/backup-firestore.js --key=path\to\serviceAccount.json
 *   node scripts/backup-firestore.js --key=... --max-reads=10000
 *
 * Writes backups/<timestamp>/ with one JSON file per top-level collection.
 * That folder is gitignored: it contains every user's data in plain text.
 *
 * Restoring
 * ---------
 * Deliberately NOT automated. A restore overwrites live data, and a script
 * that can do that by accident is more dangerous than the problem it solves.
 * The files are plain JSON keyed by document path; restoring a single user or
 * a single document is a small, deliberate piece of work you do while looking
 * at the data.
 */

require('dotenv').config();

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const arg = (name, fallback = null) => {
  const found = process.argv.find((a) => a.startsWith(`--${name}=`));
  return found ? found.slice(name.length + 3) : fallback;
};

// Half the daily free tier by default: enough to be useful, never enough to
// take the app down by exhausting reads.
const MAX_READS = Number(arg('max-reads', 25000));
const PAGE = 300;

// Everything the app cannot regenerate. Scan images are excluded on purpose:
// they live in Storage, not Firestore, and are disposable by design.
const USER_SUBCOLLECTIONS = [
  'settings',
  'private',
  'subscription',
  'usage',
  'meals',
  'dailyLogs',
];

let readsUsed = 0;

function budgetLeft() {
  return MAX_READS - readsUsed;
}

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

  console.error(
    'No credentials. Pass --key=<path to service account json>, or set\n' +
      'FIREBASE_SERVICE_ACCOUNT in backend/.env.',
  );
  process.exit(1);
}

/// Firestore Timestamps and other SDK types do not survive JSON.stringify in a
/// form you can read six months later, so they are flattened to ISO strings.
function serialize(value) {
  if (value === null || value === undefined) return value;
  if (typeof value.toDate === 'function') {
    return { __timestamp: value.toDate().toISOString() };
  }
  if (Array.isArray(value)) return value.map(serialize);
  if (typeof value === 'object' && value.constructor === Object) {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = serialize(v);
    return out;
  }
  return value;
}

async function dumpCollection(ref, out, label) {
  let cursor = null;

  for (;;) {
    if (budgetLeft() <= 0) {
      console.warn(`  read budget exhausted while copying ${label}`);
      return false;
    }

    let query = ref.orderBy('__name__').limit(Math.min(PAGE, budgetLeft()));
    if (cursor) query = query.startAfter(cursor);

    const snap = await query.get();
    if (snap.empty) return true;

    readsUsed += snap.size;
    for (const doc of snap.docs) {
      cursor = doc;
      out[doc.ref.path] = serialize(doc.data());
    }

    if (snap.size < PAGE) return true;
  }
}

async function main() {
  init();
  const db = admin.firestore();

  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const dir = path.join(__dirname, '..', '..', 'backups', stamp);
  fs.mkdirSync(dir, { recursive: true });

  console.log(`Backing up to backups/${stamp}/`);
  console.log(`Read budget: ${MAX_READS} documents\n`);

  // Per-user data, which is the part that cannot be regenerated.
  const users = {};
  let complete = true;
  let userCount = 0;
  let cursor = null;

  for (;;) {
    if (budgetLeft() <= 0) { complete = false; break; }

    let query = db.collection('users').orderBy('__name__').limit(100);
    if (cursor) query = query.startAfter(cursor);
    const snap = await query.get();
    if (snap.empty) break;

    readsUsed += snap.size;

    for (const doc of snap.docs) {
      cursor = doc;
      userCount++;
      users[doc.ref.path] = serialize(doc.data());

      for (const sub of USER_SUBCOLLECTIONS) {
        const ok = await dumpCollection(
          doc.ref.collection(sub),
          users,
          `${doc.id}/${sub}`,
        );
        if (!ok) { complete = false; break; }
      }
      if (!complete) break;

      if (userCount % 25 === 0) {
        console.log(`  ${userCount} users, ${readsUsed} reads used`);
      }
    }

    if (!complete || snap.size < 100) break;
  }

  fs.writeFileSync(
    path.join(dir, 'users.json'),
    JSON.stringify(users, null, 2),
  );

  // Top-level operational collections. Small, and useful when reconstructing
  // what happened rather than what the data was.
  for (const name of ['auditLogs', 'revenueCatEvents']) {
    const out = {};
    await dumpCollection(db.collection(name), out, name);
    fs.writeFileSync(
      path.join(dir, `${name}.json`),
      JSON.stringify(out, null, 2),
    );
  }

  const manifest = {
    takenAt: new Date().toISOString(),
    users: userCount,
    documents: Object.keys(users).length,
    readsUsed,
    complete,
    note: complete
      ? 'Full copy.'
      : 'PARTIAL — the read budget ran out. Re-run with a higher --max-reads, ' +
        'or on a quieter day. Do not treat this as a full backup.',
  };
  fs.writeFileSync(
    path.join(dir, 'manifest.json'),
    JSON.stringify(manifest, null, 2),
  );

  console.log(`\n${complete ? 'Done.' : 'PARTIAL BACKUP.'}`);
  console.log(`  users      : ${userCount}`);
  console.log(`  documents  : ${Object.keys(users).length}`);
  console.log(`  reads used : ${readsUsed} of ${MAX_READS}`);
  console.log(`  folder     : backups/${stamp}/`);
  if (!complete) {
    console.log('\n  Re-run with --max-reads=<higher> for a full copy.');
    process.exit(2);
  }
  process.exit(0);
}

main().catch((err) => {
  console.error('Backup failed:', err);
  process.exit(1);
});
