const assert = require('node:assert');
const http = require('node:http');
const test = require('node:test');
const express = require('express');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';

const { app, forwardAsyncErrors, identityKey, setAuthVerifierForTest } = require('../server');

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
          let parsed = null;
          try { parsed = data ? JSON.parse(data) : null; } catch { parsed = data; }
          resolve({ status: res.statusCode, body: parsed });
        });
      },
    );
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function withServer(handler, fn) {
  const server = http.createServer(handler);
  await new Promise((resolve) => server.listen(0, resolve));
  server.url = `http://127.0.0.1:${server.address().port}`;
  try {
    await fn(server);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

// Express 4 left a rejected async handler unhandled, which on Node 15+ ends
// the process. /api/premium-status could do that on one Firestore error.
test('an async route that throws answers 500 and the server keeps serving', async () => {
  const mini = forwardAsyncErrors(express());
  mini.get('/boom', async () => { throw new Error('firestore unavailable'); });
  mini.get('/sync-boom', () => { throw new Error('thrown synchronously'); });
  mini.get('/ok', (req, res) => res.json({ ok: true }));
  mini.use((err, req, res, next) => res.status(500).json({ error: err.message }));

  await withServer(mini, async (server) => {
    const boom = await request(server, 'GET', '/boom');
    assert.equal(boom.status, 500);
    assert.equal(boom.body.error, 'firestore unavailable');

    const syncBoom = await request(server, 'GET', '/sync-boom');
    assert.equal(syncBoom.status, 500);

    const ok = await request(server, 'GET', '/ok');
    assert.equal(ok.status, 200);
  });
});

// The limiters used to fall back to a hash of the bearer token before it was
// verified, so refreshing the token reset the allowance.
test('rate limits key on the verified user, never on an unverified token', () => {
  assert.equal(
    identityKey({ user: { uid: 'user12345' }, headers: {}, ip: '203.0.113.5' }),
    'uid:user12345',
  );
  assert.equal(
    identityKey({ headers: { authorization: 'Bearer anything-at-all' }, ip: '203.0.113.5' }),
    'ip:203.0.113.5',
  );
});

test('AI image analysis requires sign-in', async () => {
  await withServer(app, async (server) => {
    const res = await request(server, 'POST', '/api/ai/image', {
      body: { prompt: 'x', image: 'aGVsbG8=' },
    });
    assert.equal(res.status, 401);
  });
});

test('malformed AI requests are refused before any allowance is charged', async () => {
  setAuthVerifierForTest(async () => ({ uid: 'user12345', admin: false }));
  try {
    await withServer(app, async (server) => {
      const image = await request(server, 'POST', '/api/ai/image', {
        headers: { Authorization: 'Bearer valid' },
        body: { prompt: 'describe' },
      });
      assert.equal(image.status, 400);

      const text = await request(server, 'POST', '/api/ai/text', {
        headers: { Authorization: 'Bearer valid' },
        body: { prompt: '' },
      });
      assert.equal(text.status, 400);
    });
  } finally {
    setAuthVerifierForTest(null);
  }
});
