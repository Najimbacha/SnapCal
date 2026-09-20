// Keep the stricter migration policy opt-in on Render and automatic on Cloud Run.
function sharedRedisRequired(env = process.env) {
  return Boolean(env.K_SERVICE) || env.REQUIRE_SHARED_REDIS === 'true';
}

function validateRedisConfig(env = process.env) {
  if (!sharedRedisRequired(env)) return;
  let url;
  try { url = new URL(env.REDIS_URL); } catch {
    throw new Error('Shared Redis is required: configure REDIS_URL through Secret Manager.');
  }
  if (env.K_SERVICE && url.protocol !== 'rediss:') {
    throw new Error('Cloud Run requires a TLS Redis endpoint (rediss://).');
  }
}

function redisAvailabilityGuard(required, isReady) {
  return (req, res, next) => {
    if (!required || isReady()) return next();
    res.set('Retry-After', '5');
    return res.status(503).json({ error: 'Service temporarily unavailable. Please retry.' });
  };
}

// Store errors must not bypass the limit or hang waiting for a reconnect.
function protectLimiter(limiter) {
  return (req, res, next) => limiter(req, res, (error) => {
    if (!error) return next();
    console.error('Rate-limit store unavailable');
    res.set('Retry-After', '5');
    return res.status(503).json({ error: 'Service temporarily unavailable. Please retry.' });
  });
}

function shutdownSettings(env = process.env) {
  const cloudRun = Boolean(env.K_SERVICE);
  const drainMs = Number(env.SHUTDOWN_DRAIN_MS ?? (cloudRun ? 0 : 5000));
  const timeoutMs = Number(env.SHUTDOWN_TIMEOUT_MS ?? (cloudRun ? 9000 : 60000));
  if (!Number.isFinite(drainMs) || drainMs < 0 || !Number.isFinite(timeoutMs) || timeoutMs <= 0 ||
      (cloudRun && drainMs + timeoutMs > 9000)) {
    throw new Error('Invalid shutdown timing: Cloud Run requires a total deadline of at most 9000ms.');
  }
  return { drainMs, timeoutMs };
}

module.exports = { sharedRedisRequired, validateRedisConfig, redisAvailabilityGuard, protectLimiter, shutdownSettings };
