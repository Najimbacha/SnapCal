const assert = require('node:assert/strict');
const test = require('node:test');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';
process.env.REVENUECAT_SECRET_API_KEY = 'test_revenuecat_key';
process.env.REVENUECAT_RECHECK_MS = String(10 * 60 * 1000);

const axios = require('axios');
const { claimAiTextQuota } = require('../server');
const db = require('firebase-admin').firestore();

function refFor(path) {
  return {
    path,
    collection(name) {
      return {
        doc: (id) => refFor(`${path}/${name}/${id}`),
      };
    },
    async get() {
      if (path.endsWith('/subscription/current')) {
        return {
          exists: true,
          data: () => ({
            isActive: false,
            lastRestCheckAt: { toMillis: () => Date.now() },
          }),
        };
      }
      return { exists: false, data: () => ({}) };
    },
    async set() {},
  };
}

test('quota checks force a RevenueCat recheck before blocking a paying user', async () => {
  const originalCollection = db.collection;
  const originalRunTransaction = db.runTransaction;
  const originalAxiosGet = axios.get;
  const today = new Date().toISOString().slice(0, 10);
  let revenueCatCalls = 0;
  let usageWrites = 0;

  db.collection = (name) => ({
    doc: (id) => refFor(`${name}/${id}`),
  });
  db.runTransaction = async (run) => run({
    get: async (ref) => {
      if (ref.path.endsWith('/subscription/current')) {
        return { exists: true, data: () => ({ isActive: false }) };
      }
      return {
        exists: true,
        data: () => ({
          aiDayKey: today,
          aiRequestsUsed: 30,
          aiMessagesUsed: 1,
        }),
      };
    },
    set: () => { usageWrites += 1; },
  });
  axios.get = async () => {
    revenueCatCalls += 1;
    return {
      status: 200,
      data: {
        subscriber: {
          entitlements: {},
          subscriptions: {
            'snapcal_pro_monthly:monthly-plan': {
              expires_date: '2026-10-13T12:00:00.000Z',
            },
          },
        },
      },
    };
  };

  try {
    const claim = await claimAiTextQuota('payer-at-free-limit');
    assert.equal(claim.isPremium, true);
    assert.equal(revenueCatCalls, 1);
    assert.equal(usageWrites, 0, 'Pro users should not consume free AI quota');
  } finally {
    db.collection = originalCollection;
    db.runTransaction = originalRunTransaction;
    axios.get = originalAxiosGet;
  }
});
