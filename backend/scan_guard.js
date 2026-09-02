/**
 * Two cheap protections on the scan path. Neither costs anything to run.
 *
 * 1. A concurrency ceiling per instance.
 * 2. A circuit breaker per AI provider.
 *
 * Both exist for the same reason: a scan holds a request open for up to 50
 * seconds while an upstream model thinks. That is fine until it isn't, and
 * when it isn't, the failure mode is one instance accepting far more work than
 * it can hold — every request slowing down together, including the cheap ones
 * — rather than shedding the excess so the load balancer can place it
 * elsewhere. Slow is worse than refused here: a user who gets an answer in
 * three seconds or a clear "try again" is better served than one watching a
 * spinner for a minute before it fails anyway.
 */

// ── 1. Concurrency ceiling ──────────────────────────────────────────────────

const MAX_CONCURRENT_SCANS = Number(process.env.MAX_CONCURRENT_SCANS || 40);

let inFlight = 0;

function tryAcquireScanSlot() {
  if (inFlight >= MAX_CONCURRENT_SCANS) return false;
  inFlight++;
  return true;
}

function releaseScanSlot() {
  inFlight = Math.max(0, inFlight - 1);
}

function scanConcurrency() {
  return { inFlight, limit: MAX_CONCURRENT_SCANS };
}

// ── 2. Provider circuit breaker ─────────────────────────────────────────────
//
// When a provider has failed repeatedly, stop calling it for a while.
//
// Without this, an outage at the first provider in the chain costs every
// single scan its full timeout before falling through to the second — so a
// 30-second provider stall becomes 30 seconds added to every user's scan, for
// as long as the outage lasts. Skipping a known-bad provider turns that into
// no delay at all, and stops paying for calls that will fail.
//
// Deliberately per-process and in-memory: sharing breaker state through Redis
// would make a cache outage able to break scanning, and each instance observes
// enough failures on its own to trip within seconds.

const FAILURE_THRESHOLD = Number(process.env.BREAKER_FAILURE_THRESHOLD || 5);
const OPEN_MS = Number(process.env.BREAKER_OPEN_MS || 60000);

const breakers = new Map();

function breakerFor(provider) {
  let b = breakers.get(provider);
  if (!b) {
    b = { failures: 0, openedAt: 0 };
    breakers.set(provider, b);
  }
  return b;
}

/// False when the provider is being skipped right now.
function providerAvailable(provider) {
  const b = breakerFor(provider);
  if (b.openedAt === 0) return true;

  if (Date.now() - b.openedAt >= OPEN_MS) {
    // Half-open: let exactly one request through to test the water. If it
    // fails, recordProviderFailure re-opens immediately; if it succeeds, the
    // breaker resets. Anything more aggressive stampedes a recovering service.
    b.openedAt = 0;
    b.failures = FAILURE_THRESHOLD - 1;
    return true;
  }
  return false;
}

function recordProviderSuccess(provider) {
  const b = breakerFor(provider);
  b.failures = 0;
  b.openedAt = 0;
}

function recordProviderFailure(provider) {
  const b = breakerFor(provider);
  b.failures++;
  if (b.failures >= FAILURE_THRESHOLD && b.openedAt === 0) {
    b.openedAt = Date.now();
    console.error(
      `Circuit breaker OPEN for ${provider} after ${b.failures} failures; ` +
        `skipping it for ${Math.round(OPEN_MS / 1000)}s.`,
    );
  }
}

function breakerStates() {
  const out = {};
  for (const [name, b] of breakers) {
    out[name] = b.openedAt === 0 ? 'closed' : 'open';
  }
  return out;
}

// Test seam: the breaker is process state, and a test that cannot clear it
// leaks into the next one.
function resetBreakers() {
  breakers.clear();
  inFlight = 0;
}

module.exports = {
  tryAcquireScanSlot,
  releaseScanSlot,
  scanConcurrency,
  providerAvailable,
  recordProviderSuccess,
  recordProviderFailure,
  breakerStates,
  resetBreakers,
  MAX_CONCURRENT_SCANS,
};
