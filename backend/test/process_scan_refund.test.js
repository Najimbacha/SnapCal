const assert = require('node:assert/strict');
const test = require('node:test');
process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';

const http = require('node:http');
const { app, setAuthVerifierForTest } = require('../server');
const db = require('firebase-admin').firestore();

// In-memory Firestore stand-in keyed by document path.
function fakeFirestore(initial) {
  const docs = new Map(Object.entries(initial));
  const refFor = (path) => ({
    path,
    collection: (name) => ({ doc: (id) => refFor(`${path}/${name}/${id}`) }),
    async get() { return snapshot(path); },
    async set(update) { docs.set(path, { ...(docs.get(path) || {}), ...update }); },
  });
  const snapshot = (path) => ({ exists: docs.has(path), data: () => docs.get(path) || {} });
  const merge = (ref, update) => docs.set(ref.path, { ...(docs.get(ref.path) || {}), ...update });
  return {
    docs,
    collection: (name) => ({ doc: (id) => refFor(`${name}/${id}`) }),
    runTransaction: async (body) => body({
      get: async (ref) => snapshot(ref.path),
      set: (ref, update) => merge(ref, update),
      update: (ref, update) => merge(ref, update),
    }),
  };
}

async function processFailingScan({ pro, usage }) {
  const uid = 'user1';
  const today = new Date().toISOString().slice(0, 10);
  const fake = fakeFirestore({
    [`users/${uid}/foodScans/scan-0001-abcd`]: { status: 'uploaded', storagePath: 'not-an-owned-path' },
    [`users/${uid}/usage/currentMonth`]: usage(today),
    [`users/${uid}/subscription/current`]: { isActive: pro },
  });
  const original = { collection: db.collection, runTransaction: db.runTransaction };
  db.collection = fake.collection;
  db.runTransaction = fake.runTransaction;
  setAuthVerifierForTest(async () => ({ uid }));
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    const response = await fetch(`http://127.0.0.1:${server.address().port}/api/food-scans/scan-0001-abcd/process`, {
      method: 'POST',
      headers: { Authorization: 'Bearer test' },
    });
    await response.json();
    return { status: response.status, usage: fake.docs.get(`users/${uid}/usage/currentMonth`), scan: fake.docs.get(`users/${uid}/foodScans/scan-0001-abcd`) };
  } finally {
    setAuthVerifierForTest(null);
    db.collection = original.collection;
    db.runTransaction = original.runTransaction;
    await new Promise((resolve) => server.close(resolve));
  }
}

const month = new Date().toISOString().slice(0, 7);

test('a free user is not charged for a scan that fails to process', async () => {
  const result = await processFailingScan({ pro: false, usage: () => ({ monthKey: month, scansUsed: 3 }) });
  assert.equal(result.status, 500);
  assert.equal(result.scan.status, 'failed');
  assert.equal(result.usage.scansUsed, 3, 'the failed scan is given back');
});

test('a Pro user is not charged against the daily fair-use count for a failed scan', async () => {
  const result = await processFailingScan({
    pro: true,
    usage: (today) => ({ monthKey: month, scansUsed: 3, proScanDayKey: today, proScansToday: 5 }),
  });
  assert.equal(result.status, 500);
  assert.equal(result.usage.scansUsed, 3);
  assert.equal(result.usage.proScansToday, 5);
});
