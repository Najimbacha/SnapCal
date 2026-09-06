const test = require('node:test');
const assert = require('node:assert/strict');
const { createRequestCoalescer, logAiUsage } = require('../services/ai_cost_controls');

test('same user and request share only concurrent paid work', async () => {
  const coalesce = createRequestCoalescer();
  let calls = 0;
  let finish;
  const operation = () => { calls++; return new Promise(resolve => { finish = resolve; }); };
  const a = coalesce('alice', ['hello', 100], operation);
  const b = coalesce('alice', ['hello', 100], operation);
  await Promise.resolve();
  assert.equal(calls, 1);
  finish('reply');
  assert.deepEqual(await Promise.all([a, b]), ['reply', 'reply']);
  assert.equal(await coalesce('alice', ['hello', 100], async () => { calls++; return 'new'; }), 'new');
  assert.equal(calls, 2);
});

test('users and generation options stay isolated', async () => {
  const coalesce = createRequestCoalescer();
  let calls = 0;
  const run = async () => ++calls;
  await Promise.all([coalesce('a', ['p', 100], run), coalesce('b', ['p', 100], run), coalesce('a', ['p', 200], run)]);
  assert.equal(calls, 3);
});

test('failures clear pending work so a later retry can succeed', async () => {
  const coalesce = createRequestCoalescer();
  const fail = () => { throw new Error('offline'); };
  const results = await Promise.allSettled([coalesce('a', 'p', fail), coalesce('a', 'p', fail)]);
  assert.ok(results.every(r => r.status === 'rejected'));
  assert.equal(await coalesce('a', 'p', () => 'ok'), 'ok');
});

test('capacity does not prevent new paid requests from running', async () => {
  const coalesce = createRequestCoalescer(1);
  let finish;
  const waiting = coalesce('a', 1, () => new Promise(resolve => { finish = resolve; }));
  await Promise.resolve();
  assert.equal(await coalesce('b', 1, () => 'ok'), 'ok');
  finish('done');
  await waiting;
});

test('usage logs contain counts without request or response text', t => {
  const log = t.mock.method(console, 'log', () => {});
  logAiUsage('text', 'test-model', { usage: { prompt_tokens: 123, completion_tokens: 10, total_tokens: 133, prompt_cache_hit_tokens: 100, secret: 'private' }, choices: [{ message: { content: 'private' } }] });
  const output = JSON.parse(log.mock.calls[0].arguments[0]);
  assert.equal(output.total_tokens, 133);
  assert.equal(output.prompt_cache_hit_tokens, 100);
  assert.equal(JSON.stringify(output).includes('private'), false);
  logAiUsage('text', 'test-model', {});
  assert.equal(log.mock.callCount(), 1);
});
