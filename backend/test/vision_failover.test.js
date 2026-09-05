const test = require('node:test');
const assert = require('node:assert/strict');
const axios = require('axios');

process.env.NODE_ENV = 'test';
const { callAiWithImage, fillMissingNutrition } = require('../server');
const { resetBreakers, recordProviderFailure, breakerStates } = require('../scan_guard');

const reply = (content) => ({ data: { choices: [{ message: { content } }] } });
const valid = '{"foods":[]}';

test.beforeEach((t) => {
  const values = {
    AI_IMAGE_PROVIDER_ORDER: 'groq,deepseek',
    GROQ_API_KEY: 'test-groq',
    DEEPSEEK_API_KEY: 'test-deepseek',
    AI_RETRY_LIMIT: '1',
    AI_TEXT_PROVIDER_ORDER: 'deepseek',
  };
  const previous = Object.fromEntries(Object.keys(values).map(key => [key, process.env[key]]));
  Object.assign(process.env, values);
  resetBreakers();
  t.after(() => {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
    resetBreakers();
  });
});

for (const [label, content] of [
  ['think-only', '<think>Still identifying the food'],
  ['prose', 'This looks like rice.'],
  ['truncated JSON', '{"foods":['],
  ['malformed JSON', '{"foods": invalid}'],
  ['missing foods', '{"message":"Unable to answer"}'],
]) {
  test(`${label} falls through to the next provider`, async (t) => {
    const urls = [];
    t.mock.method(axios, 'post', async (url) => {
      urls.push(url);
      return reply(urls.length === 1 ? content : valid);
    });
    assert.equal(await callAiWithImage('test-image', 'en', null, true), valid);
    assert.deepEqual(urls, [
      'https://api.groq.com/openai/v1/chat/completions',
      'https://api.deepseek.com/chat/completions',
    ]);
  });
}

test('invalid JSON counts toward opening the provider circuit', async (t) => {
  const threshold = Number(process.env.BREAKER_FAILURE_THRESHOLD) || 5;
  for (let i = 1; i < threshold; i++) recordProviderFailure('groq');
  t.mock.method(axios, 'post', async (url) => reply(url.includes('groq') ? 'Not JSON' : valid));
  await callAiWithImage('test-image', 'en', null, true);
  assert.equal(breakerStates().groq, 'open');
  assert.equal(breakerStates().deepseek, 'closed');
});

test('repairable JSON succeeds without another provider call', async (t) => {
  const post = t.mock.method(axios, 'post', async () => reply('{"foods":[],}'));
  assert.equal(await callAiWithImage('test-image', 'en', null, true), valid);
  assert.equal(post.mock.callCount(), 1);
});

test('all invalid providers reject the scan', async (t) => {
  const post = t.mock.method(axios, 'post', async () => reply('Not JSON'));
  await assert.rejects(callAiWithImage('test-image', 'en', null, true), /json-not-found/);
  assert.equal(post.mock.callCount(), 2);
});

test('custom image prompts still accept plain text', async (t) => {
  const post = t.mock.method(axios, 'post', async () => reply('A plate of rice.'));
  assert.equal(await callAiWithImage('test-image', 'en', 'Describe the picture'), 'A plate of rice.');
  assert.equal(post.mock.callCount(), 1);
});

test('default image routing only calls DeepSeek', async (t) => {
  delete process.env.AI_IMAGE_PROVIDER_ORDER;
  const urls = [];
  t.mock.method(axios, 'post', async (url, body) => {
    urls.push(url);
    assert.deepEqual(body.thinking, { type: 'disabled' });
    return reply(valid);
  });
  await callAiWithImage('test-image', 'en', null, true);
  assert.deepEqual(urls, ['https://api.deepseek.com/chat/completions']);
});

test('DeepSeek thinking setting is not sent to other providers', async (t) => {
  process.env.AI_IMAGE_PROVIDER_ORDER = 'groq';
  t.mock.method(axios, 'post', async (_url, body) => {
    assert.equal(Object.hasOwn(body, 'thinking'), false);
    return reply(valid);
  });
  await callAiWithImage('test-image', 'en', null, true);
});

const unresolved = (name, weight = 100) => ({
  items: [{ match_key: name, weight_g: weight, nutrition_source: 'unresolved', nutrition: null }],
});

test('repeated nutrition lookup reuses values but recalculates portion size', async (t) => {
  const name = 'cache test rice';
  const post = t.mock.method(axios, 'post', async () => reply(JSON.stringify({
    foods: { [name]: { calories: 160, protein_g: 10, carbs_g: 30, fat_g: 0 } },
  })));
  const first = await fillMissingNutrition(unresolved(name));
  const second = await fillMissingNutrition(unresolved(name, 250));
  assert.equal(first.items[0].calories, 160);
  assert.equal(second.items[0].calories, 400);
  assert.equal(second.totals.calories, 400);
  assert.equal(post.mock.callCount(), 1);
});

test('failed nutrition lookups are retried on a later scan', async (t) => {
  const post = t.mock.method(axios, 'post', async () => { throw new Error('offline'); });
  await fillMissingNutrition(unresolved('cache retry food'));
  await fillMissingNutrition(unresolved('cache retry food'));
  assert.equal(post.mock.callCount(), 2);
});

test('expired nutrition estimates are fetched again', async (t) => {
  const name = 'cache expired food';
  const post = t.mock.method(axios, 'post', async () => reply(JSON.stringify({
    foods: { [name]: { calories: 160, protein_g: 10, carbs_g: 30, fat_g: 0 } },
  })));
  await fillMissingNutrition(unresolved(name));
  const later = Date.now() + 25 * 60 * 60 * 1000;
  t.mock.method(Date, 'now', () => later);
  await fillMissingNutrition(unresolved(name));
  assert.equal(post.mock.callCount(), 2);
});
