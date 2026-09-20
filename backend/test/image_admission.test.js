const test = require('node:test');
const assert = require('node:assert/strict');
Object.assign(process.env, { NODE_ENV: 'test', MAX_CONCURRENT_SCANS: '1', REDIS_URL: '', REQUIRE_SHARED_REDIS: 'false', K_SERVICE: '' });
const { app } = require('../server');
const { tryAcquireScanSlot, releaseScanSlot } = require('../scan_guard');

test('full scan admission rejects before parsing an image body, while startup remains available', async () => {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  assert.equal(tryAcquireScanSlot(), true);
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    for (const route of ['/v1/scan', '/api/ai/image']) {
      const response = await fetch(base + route, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{broken-json' });
      assert.equal(response.status, 503, 'a busy server must reject before touching the malformed body');
      assert.equal(response.headers.get('retry-after'), '5');
      await response.text();
    }
    const response = await fetch(base + '/startup');
    assert.equal(response.status, 200);
    await response.text();
  } finally { releaseScanSlot(); await new Promise(resolve => server.close(resolve)); }
});
