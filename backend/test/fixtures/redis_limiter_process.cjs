const express = require('express');
const { createClient } = require('redis');
const { rateLimit } = require('express-rate-limit');
const { createSharedRateLimitStore } = require('../../shared_rate_limit_store');
const { protectLimiter, redisAvailabilityGuard } = require('../../cloud_run_runtime');

(async () => {
  const client = createClient({ url: process.env.TEST_REDIS_URL, disableOfflineQueue: true, socket: { connectTimeout: 5000, reconnectStrategy: false } });
  client.on('error', () => {});
  await client.connect();
  const cache = { isReady: () => client.isReady, getClient: () => client };
  const app = express();
  app.use(redisAvailabilityGuard(true, cache.isReady));
  app.use(protectLimiter(rateLimit({
    windowMs: 60000, limit: 3, keyGenerator: () => 'same-user',
    store: createSharedRateLimitStore(cache, process.env.TEST_PREFIX),
  })));
  app.get('/', (req, res) => res.sendStatus(200));
  const server = app.listen(0, '127.0.0.1', () => process.send({ port: server.address().port }));
  process.on('message', async message => {
    if (message === 'disconnect') { await client.disconnect(); process.send({ disconnected: true }); }
  });
})().catch(() => { process.send({ error: 'Redis integration setup failed' }); process.exit(1); });
