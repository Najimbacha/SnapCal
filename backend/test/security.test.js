const assert = require('node:assert');
const http = require('node:http');
const test = require('node:test');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';
process.env.REVENUECAT_WEBHOOK_AUTH = 'Bearer test-webhook-secret';

const { app, normalizeNutrition, isSafeId, setAuthVerifierForTest } = require('../server');

function request(server, method, path, { headers = {}, body } = {}) {
  return new Promise((resolve, reject) => {
    const payload = body === undefined ? undefined : JSON.stringify(body);
    const req = http.request(
      server.url + path,
      {
        method,
        headers: {
          ...(payload ? { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) } : {}),
          ...headers,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          resolve({
            status: res.statusCode,
            body: data ? JSON.parse(data) : null,
          });
        });
      },
    );
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function withServer(fn) {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  server.url = `http://127.0.0.1:${server.address().port}`;
  try {
    await fn(server);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('helper validation rejects unsafe IDs', () => {
  assert.equal(isSafeId('valid_12345'), true);
  assert.equal(isSafeId('../bob'), false);
});

test('nutrition parser normalizes bounded result fields', () => {
  const parsed = normalizeNutrition('{"items":[{"food_name":"Rice","calories":999999,"protein":3,"carbs":45,"fat":2}]}');
  assert.equal(parsed.items[0].calories, 5000);
  assert.equal(parsed.items[0].food_name, 'Rice');
});

test('missing auth token is rejected', async () => {
  await withServer(async (server) => {
    const res = await request(server, 'GET', '/api/premium-status');
    assert.equal(res.status, 401);
  });
});

test('invalid auth token is rejected', async () => {
  setAuthVerifierForTest(async () => {
    throw new Error('invalid token');
  });
  await withServer(async (server) => {
    const res = await request(server, 'GET', '/api/premium-status', {
      headers: { Authorization: 'Bearer invalid' },
    });
    assert.equal(res.status, 401);
  });
  setAuthVerifierForTest(null);
});

test('non-admin cannot call admin endpoint', async () => {
  setAuthVerifierForTest(async () => ({ uid: 'user12345', admin: false }));
  await withServer(async (server) => {
    const res = await request(server, 'GET', '/api/admin/users/target12345/summary', {
      headers: { Authorization: 'Bearer valid' },
    });
    assert.equal(res.status, 403);
  });
  setAuthVerifierForTest(null);
});

test('RevenueCat webhook rejects incorrect authorization header', async () => {
  await withServer(async (server) => {
    const res = await request(server, 'POST', '/api/revenuecat/webhook', {
      headers: { Authorization: 'Bearer wrong' },
      body: { event: { id: 'event1', app_user_id: 'user12345', type: 'INITIAL_PURCHASE' } },
    });
    assert.equal(res.status, 401);
  });
});
