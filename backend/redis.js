/**
 * The one shared Redis connection.
 *
 * It backs two things: the rate limiters (so a limit means the same thing
 * across every instance) and the entitlement cache (so a Pro user's app launch
 * does not read Firestore once per request).
 *
 * Subscription/scan caches degrade to misses. Rate limiting is different:
 * Cloud Run requires Redis and fails closed while it is unavailable. Eviction
 * can reset counters, so monitor capacity as well as connection health.
 */
const REDIS_URL = process.env.REDIS_URL || '';
const { validateRedisConfig } = require('./cloud_run_runtime');
validateRedisConfig();

let client = null;
let ready = false;
let loggedFailure = false;

function init() {
  if (client || !REDIS_URL) return client;

  try {
    const { createClient } = require('redis');
    client = createClient({
      url: REDIS_URL,
      disableOfflineQueue: true,
      socket: { connectTimeout: 5000 },
    });
    client.on('error', (err) => {
      ready = false;
      if (!loggedFailure) {
        console.error('Redis error (cache degrades to miss):', err.message);
        loggedFailure = true;
      }
    });
    client.on('ready', () => {
      ready = true;
      loggedFailure = false;
      console.log('Redis connected');
    });
    client.on('reconnecting', () => { ready = false; });
    client.on('end', () => { ready = false; });
    client.connect().catch((err) => {
      console.error('Redis connect failed:', err.message);
    });
  } catch (err) {
    console.error('REDIS_URL set but the redis client could not load:', err.message);
    client = null;
  }
  return client;
}

function getClient() {
  return client;
}

function isReady() {
  return Boolean(client) && ready;
}

/// Reads JSON at `key`. Returns null on a miss, on malformed data, or when
/// Redis is unavailable — the caller cannot tell the difference and should not
/// need to.
async function getJson(key) {
  if (!isReady()) return null;
  try {
    const raw = await client.get(key);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch (err) {
    return null;
  }
}

/// Writes JSON with a TTL. Failures are swallowed: a cache that cannot be
/// written is a performance problem, never a correctness one.
async function setJson(key, value, ttlSeconds) {
  if (!isReady()) return false;
  try {
    await client.set(key, JSON.stringify(value), { EX: ttlSeconds });
    return true;
  } catch (err) {
    return false;
  }
}

async function del(key) {
  if (!isReady()) return false;
  try {
    await client.del(key);
    return true;
  } catch (err) {
    return false;
  }
}

module.exports = { init, getClient, isReady, getJson, setJson, del, REDIS_URL };
