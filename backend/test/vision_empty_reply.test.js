const test = require('node:test');
const assert = require('node:assert');

process.env.NODE_ENV = 'test';
const { stripThink, extractJson } = require('../server');

/// The shape of the outage: a reasoning model that ran out of budget before it
/// finished thinking. `content` is not empty, so a truthiness check on the raw
/// string passes -- but there is no answer in it.
const THINK_ONLY = '<think>The plate appears to contain rice and some kind of';

test('a think-only reply is non-empty raw but empty once stripped', () => {
  assert.ok(THINK_ONLY.length > 0, 'precondition: raw content is truthy');
  assert.strictEqual(stripThink(THINK_ONLY), '');
});

test('a closed think block with no answer also strips to empty', () => {
  assert.strictEqual(stripThink('<think>weighing the options</think>'), '');
});

test('a real answer survives stripping', () => {
  const reply = '<think>rice, chicken</think>{"items":[]}';
  assert.strictEqual(stripThink(reply), '{"items":[]}');
});

/// Why the check order matters: this is what the caller did with the empty
/// string once the provider had been credited with a success.
test('extractJson on the stripped-empty string is the json-not-found seen in logs', () => {
  assert.throws(
    () => extractJson(stripThink(THINK_ONLY)),
    (err) => err.message === 'json-not-found: ',
  );
});
