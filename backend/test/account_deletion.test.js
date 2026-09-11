const assert = require('node:assert');
const http = require('node:http');
const test = require('node:test');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';

const { app, setAuthVerifierForTest, setAccountDeletionForTest } = require('../server');

function request(server, method, path, headers = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request(server.url + path, { method, headers }, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body: data }));
    });
    req.on('error', reject);
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

function recordingSteps({ failAt } = {}) {
  const calls = [];
  const step = (name) => async (uid) => {
    calls.push(`${name}:${uid}`);
    if (name === failAt) throw new Error(`${name} failed`);
  };
  return {
    calls,
    steps: {
      deleteFiles: step('files'),
      deleteData: step('data'),
      deleteLogin: step('login'),
    },
  };
}

setAuthVerifierForTest(async (token) => {
  if (token !== 'good-token') throw new Error('bad token');
  return { uid: 'user-abc123' };
});

test('account deletion needs a signed-in caller', async () => {
  const { calls, steps } = recordingSteps();
  setAccountDeletionForTest(steps);
  await withServer(async (server) => {
    const res = await request(server, 'DELETE', '/api/account');
    assert.equal(res.status, 401);
  });
  assert.deepEqual(calls, []);
});

test('deletes the caller\'s files and data, then their login', async () => {
  const { calls, steps } = recordingSteps();
  setAccountDeletionForTest(steps);
  await withServer(async (server) => {
    const res = await request(server, 'DELETE', '/api/account', { Authorization: 'Bearer good-token' });
    assert.equal(res.status, 204);
  });
  assert.deepEqual(calls, ['files:user-abc123', 'data:user-abc123', 'login:user-abc123']);
});

test('a failed data delete keeps the login, so the user can try again', async () => {
  const { calls, steps } = recordingSteps({ failAt: 'data' });
  setAccountDeletionForTest(steps);
  await withServer(async (server) => {
    const res = await request(server, 'DELETE', '/api/account', { Authorization: 'Bearer good-token' });
    assert.ok(res.status >= 500, `expected a server error, got ${res.status}`);
  });
  assert.deepEqual(calls, ['files:user-abc123', 'data:user-abc123']);
});

test('the terms of service page is served', async () => {
  await withServer(async (server) => {
    const res = await request(server, 'GET', '/terms');
    assert.equal(res.status, 200);
    assert.match(res.headers['content-type'], /text\/html/);
    assert.match(res.body, /SnapCal Terms of Service/);
  });
});
