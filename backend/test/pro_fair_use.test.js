const assert = require('node:assert/strict');
const test = require('node:test');
process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';
process.env.PRO_DAILY_SCANS = '3';
process.env.PRO_DAILY_AI_REQUESTS = '2';

const http = require('node:http');
const {
  app,
  setAuthVerifierForTest,
  claimAiTextQuota,
  refundAiTextQuota,
  claimScanQuotaForScan,
  refundScanQuota,
  clampAiTextOptions,
} = require('../server');
const db = require('firebase-admin').firestore();

// A one-user Firestore stand-in: the usage document is `state.usage`, and the
// subscription document says whether the user is Pro.
async function withUser({ pro, usage = {} }, run) {
  const original = db.runTransaction;
  const state = { usage: { ...usage } };
  db.runTransaction = async (body) => body({
    get: async (ref) => ({
      exists: true,
      data: () => (ref.path.includes('/subscription/') ? { isActive: pro } : state.usage),
    }),
    set: (ref, update) => { state.usage = { ...state.usage, ...update }; },
  });
  try {
    await run(state);
  } finally {
    db.runTransaction = original;
  }
}

test('Pro AI requests stop at the daily fair-use ceiling with a 429, not a 402', async () => {
  await withUser({ pro: true }, async (state) => {
    await claimAiTextQuota('pro-user');
    await claimAiTextQuota('pro-user');
    assert.equal(state.usage.proAiRequestsUsed, 2);
    await assert.rejects(claimAiTextQuota('pro-user'), (e) => e.code === 429 && e.kind === 'pro_ai_fair_use');
    assert.equal(state.usage.proAiRequestsUsed, 2, 'a refused request is not counted');
  });
});

test('the HTTP endpoints answer a Pro user over the ceiling with 429, never a paywall 402', async () => {
  const today = new Date().toISOString().slice(0, 10);
  const usage = { proAiDayKey: today, proAiRequestsUsed: 2, proScanDayKey: today, proScansToday: 3 };
  await withUser({ pro: true, usage }, async () => {
    setAuthVerifierForTest(async () => ({ uid: 'pro-user' }));
    const server = http.createServer(app);
    await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
    try {
      const post = (path, body) => fetch(`http://127.0.0.1:${server.address().port}${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer test' },
        body: JSON.stringify(body),
      });
      const text = await post('/api/ai/text', { prompt: 'Plan my week' });
      assert.equal(text.status, 429);
      assert.match((await text.json()).error, /fair-use/);
      const image = await post('/api/ai/image', { prompt: 'x', image: 'AAAA' });
      assert.equal(image.status, 429);
      await image.json();
    } finally {
      setAuthVerifierForTest(null);
      await new Promise((resolve) => server.close(resolve));
    }
  });
});

test('the Pro AI counter resets on a new day and a failed call is refunded', async () => {
  await withUser({ pro: true, usage: { proAiDayKey: '2000-01-01', proAiRequestsUsed: 2 } }, async (state) => {
    const claim = await claimAiTextQuota('pro-user');
    assert.equal(state.usage.proAiRequestsUsed, 1, 'yesterday\'s count does not carry over');
    await refundAiTextQuota('pro-user', claim);
    assert.equal(state.usage.proAiRequestsUsed, 0);
  });
});

test('Pro scans stop at the daily ceiling and a failed scan is refunded', async () => {
  await withUser({ pro: true }, async (state) => {
    const claims = [];
    for (let i = 0; i < 3; i++) claims.push(await claimScanQuotaForScan('pro-user'));
    assert.equal(state.usage.proScansToday, 3);
    await assert.rejects(claimScanQuotaForScan('pro-user'), (e) => e.code === 429 && e.kind === 'pro_scan_fair_use');
    assert.equal(state.usage.scansUsed, 3, 'a refused scan is not counted');

    await refundScanQuota('pro-user', claims[0].monthKey, claims[0]);
    assert.equal(state.usage.proScansToday, 2);
    assert.equal(state.usage.scansUsed, 2);
    await claimScanQuotaForScan('pro-user');
    assert.equal(state.usage.proScansToday, 3);
  });
});

test('free users are unaffected by the Pro ceilings', async () => {
  await withUser({ pro: false }, async (state) => {
    const claim = await claimScanQuotaForScan('free-user');
    assert.equal(claim.isPremium, false);
    assert.equal('proScansToday' in state.usage, false);
    await refundScanQuota('free-user', claim.monthKey, claim);
    assert.equal(state.usage.scansUsed, 0);
  });
});

test('text options are clamped to what the app needs', () => {
  const free = clampAiTextOptions({ maxOutputTokens: 8192, timeoutMs: 55000 });
  assert.equal(free.maxOutputTokens, 2048);
  assert.equal(free.timeout, 30000);

  const planner = clampAiTextOptions({
    maxOutputTokens: 8192, timeoutMs: 55000, responseMimeType: 'application/json',
  });
  assert.equal(planner.maxOutputTokens, 8192);
  assert.equal(planner.timeout, 55000);
  assert.equal(planner.requireJson, true);

  assert.equal(clampAiTextOptions({ maxOutputTokens: 500, timeoutMs: 25000 }).maxOutputTokens, 500);
  assert.equal(clampAiTextOptions({ responseMimeType: 'application/json', maxOutputTokens: 99999 }).maxOutputTokens, 8192);
});

test('malformed text options fall back to defaults instead of NaN', () => {
  for (const bad of ['abc', -5, 0, NaN, null, {}, [], Infinity]) {
    const options = clampAiTextOptions({ maxOutputTokens: bad, timeoutMs: bad, temperature: bad });
    assert.ok(Number.isFinite(options.maxOutputTokens) && options.maxOutputTokens >= 1, `tokens for ${String(bad)}`);
    assert.ok(Number.isFinite(options.timeout) && options.timeout >= 1000, `timeout for ${String(bad)}`);
    assert.ok(Number.isFinite(options.temperature), `temperature for ${String(bad)}`);
  }
  assert.equal(clampAiTextOptions({ temperature: 9 }).temperature, 2);
  assert.equal(clampAiTextOptions({ temperature: -1 }).temperature, 0);
});
