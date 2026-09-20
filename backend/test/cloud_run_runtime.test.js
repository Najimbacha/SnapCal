const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { rateLimit } = require('express-rate-limit');
const { sharedRedisRequired, validateRedisConfig, redisAvailabilityGuard, protectLimiter, shutdownSettings } = require('../cloud_run_runtime');
const { createSharedRateLimitStore } = require('../shared_rate_limit_store');

test('Cloud Run requires TLS Redis; Render keeps its existing opt-in behavior', () => {
  assert.equal(sharedRedisRequired({ K_SERVICE: 'snapcal-api' }), true);
  assert.equal(sharedRedisRequired({ NODE_ENV: 'production' }), false);
  assert.throws(() => validateRedisConfig({ K_SERVICE: 'snapcal-api' }), /Shared Redis/);
  assert.throws(() => validateRedisConfig({ K_SERVICE: 'snapcal-api', REDIS_URL: 'redis://internal:6379' }), /TLS/);
  assert.doesNotThrow(() => validateRedisConfig({ K_SERVICE: 'snapcal-api', REDIS_URL: 'rediss://cache.example:6379' }));
});

test('Cloud Run shutdown fits the platform deadline and accepts a zero drain', () => {
  assert.deepEqual(shutdownSettings({ K_SERVICE: 'test' }), { drainMs: 0, timeoutMs: 9000 });
  assert.deepEqual(shutdownSettings({}), { drainMs: 5000, timeoutMs: 60000 });
  assert.throws(() => shutdownSettings({ K_SERVICE: 'test', SHUTDOWN_DRAIN_MS: '5000' }), /9000ms/);
  assert.throws(() => shutdownSettings({ SHUTDOWN_TIMEOUT_MS: 'NaN' }), /Invalid/);
});

test('Redis loss blocks paid work with 503; process probe survives and recovery restores service', async () => {
  let ready = false;
  let paidCalls = 0;
  const app = express();
  app.get('/startup', (req, res) => res.sendStatus(200));
  app.use('/api', redisAvailabilityGuard(true, () => ready));
  app.get('/api/scan', (req, res) => { paidCalls++; res.sendStatus(200); });
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    let res = await fetch(`${base}/api/scan`);
    assert.equal(res.status, 503);
    assert.equal(res.headers.get('retry-after'), '5');
    await res.text();
    res = await fetch(`${base}/startup`);
    assert.equal(res.status, 200);
    await res.text();
    assert.equal(paidCalls, 0);
    ready = true;
    res = await fetch(`${base}/api/scan`);
    assert.equal(res.status, 200);
    await res.text();
    assert.equal(paidCalls, 1);
  } finally { await new Promise(resolve => server.close(resolve)); }
});

test('a store failure after the readiness check cannot bypass rate limits', async () => {
  const cache = { isReady: () => true, getClient: () => ({ sendCommand: async () => { throw new Error('connection lost'); } }) };
  const app = express();
  let paidCalls = 0;
  app.use(protectLimiter(rateLimit({ windowMs: 60000, limit: 1, store: createSharedRateLimitStore(cache, 'test:') })));
  app.get('/', (req, res) => { paidCalls++; res.sendStatus(200); });
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  try {
    const res = await fetch(`http://127.0.0.1:${server.address().port}`);
    assert.equal(res.status, 503);
    await res.text();
    assert.equal(paidCalls, 0);
  } finally { await new Promise(resolve => server.close(resolve)); }
});
