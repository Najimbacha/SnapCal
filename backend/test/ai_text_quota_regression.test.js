const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');
process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';
const { app, claimAiTextQuota, refundAiTextQuota, setAuthVerifierForTest } = require('../server');
const db = require('firebase-admin').firestore();

test('arbitrary prompts share the free coach quota regardless of client purpose', async () => {
  let usage = {};
  let subscription = {};
  const original = db.runTransaction;
  db.runTransaction = async (run) => run({
    get: async (ref) => ({ exists: true, data: () => ref.path.includes('/subscription/') ? subscription : usage }),
    set: (ref, update) => { usage = { ...usage, ...update }; },
  });
  setAuthVerifierForTest(async () => ({ uid: 'quota-user' }));
  const server = http.createServer(app);
  try {
    const claim = await claimAiTextQuota('quota-user');
    assert.equal(usage.aiMessagesUsed, 1);
    assert.equal(usage.aiRequestsUsed, 1);
    await assert.rejects(claimAiTextQuota('quota-user'), (e) => e.code === 402);
    await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
    for (const purpose of [undefined, 'coach', 'planner', 'unknown']) {
      const res = await fetch(`http://127.0.0.1:${server.address().port}/api/ai/text`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer test' },
        body: JSON.stringify({ prompt: 'Give me meal advice', purpose }),
      });
      assert.equal(res.status, 402, `purpose ${purpose} must not bypass quota`);
      await res.json();
    }
    await refundAiTextQuota('quota-user', claim);
    assert.equal(usage.aiMessagesUsed, 0);
    assert.equal(usage.aiRequestsUsed, 0);
    await claimAiTextQuota('quota-user');
    subscription = { isActive: true };
    assert.equal((await claimAiTextQuota('quota-user')).isPremium, true);
    assert.equal(usage.aiMessagesUsed, 1, 'Pro does not consume a free message');
  } finally {
    setAuthVerifierForTest(null);
    db.runTransaction = original;
    if (server.listening) await new Promise((resolve) => server.close(resolve));
  }
});
