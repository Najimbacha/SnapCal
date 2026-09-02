const test = require('node:test');
const assert = require('node:assert');

process.env.BREAKER_FAILURE_THRESHOLD = '3';
process.env.BREAKER_OPEN_MS = '50';

const guard = require('../scan_guard');

test.beforeEach(() => guard.resetBreakers());

test('the breaker opens only after the failure threshold', () => {
  assert.strictEqual(guard.providerAvailable('groq'), true);
  guard.recordProviderFailure('groq');
  guard.recordProviderFailure('groq');
  assert.strictEqual(guard.providerAvailable('groq'), true, 'two failures is not an outage');
  guard.recordProviderFailure('groq');
  assert.strictEqual(guard.providerAvailable('groq'), false, 'third failure opens it');
});

test('a success resets the failure count', () => {
  guard.recordProviderFailure('gemini');
  guard.recordProviderFailure('gemini');
  guard.recordProviderSuccess('gemini');
  guard.recordProviderFailure('gemini');
  assert.strictEqual(guard.providerAvailable('gemini'), true);
});

test('the breaker half-opens after the cooldown and lets one request test it', async () => {
  for (let i = 0; i < 3; i++) guard.recordProviderFailure('deepseek');
  assert.strictEqual(guard.providerAvailable('deepseek'), false);

  await new Promise((r) => setTimeout(r, 60));

  // One probe is allowed through...
  assert.strictEqual(guard.providerAvailable('deepseek'), true);
  // ...and if it fails, the breaker re-opens on that single failure rather
  // than needing another full threshold. Otherwise a dead provider is retried
  // in bursts forever.
  guard.recordProviderFailure('deepseek');
  assert.strictEqual(guard.providerAvailable('deepseek'), false);
});

test('a recovered provider closes the breaker', async () => {
  for (let i = 0; i < 3; i++) guard.recordProviderFailure('openrouter');
  await new Promise((r) => setTimeout(r, 60));
  assert.strictEqual(guard.providerAvailable('openrouter'), true);
  guard.recordProviderSuccess('openrouter');
  assert.strictEqual(guard.providerAvailable('openrouter'), true);
  assert.strictEqual(guard.breakerStates().openrouter, 'closed');
});

test('breakers are independent per provider', () => {
  for (let i = 0; i < 3; i++) guard.recordProviderFailure('groq');
  assert.strictEqual(guard.providerAvailable('groq'), false);
  assert.strictEqual(guard.providerAvailable('gemini'), true);
});

test('scan slots are handed out up to the ceiling and then refused', () => {
  const limit = guard.MAX_CONCURRENT_SCANS;
  for (let i = 0; i < limit; i++) {
    assert.strictEqual(guard.tryAcquireScanSlot(), true, `slot ${i} should be free`);
  }
  assert.strictEqual(guard.tryAcquireScanSlot(), false, 'past the ceiling, shed');
  assert.strictEqual(guard.scanConcurrency().inFlight, limit);

  guard.releaseScanSlot();
  assert.strictEqual(guard.tryAcquireScanSlot(), true, 'a freed slot is reusable');
});

test('releasing more than acquired cannot drive the count negative', () => {
  // The route releases on both 'finish' and 'close', which can both fire. A
  // negative count would silently raise the real ceiling.
  guard.releaseScanSlot();
  guard.releaseScanSlot();
  assert.strictEqual(guard.scanConcurrency().inFlight, 0);
});
