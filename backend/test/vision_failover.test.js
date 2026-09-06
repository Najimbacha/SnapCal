const test = require('node:test');
const assert = require('node:assert/strict');
const axios = require('axios');
const redisCache = require('../redis');

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

test('v2 uses the smaller detection budget and lower temperature', async (t) => {
  process.env.AI_IMAGE_PROVIDER_ORDER = 'deepseek';
  t.mock.method(axios, 'post', async (_url, body) => {
    assert.equal(body.max_tokens, 1536);
    assert.equal(body.temperature, 0.2);
    return reply(valid);
  });
  await callAiWithImage('test-image', 'en', null, true);
});

test('a token-limit response is not purchased repeatedly', async (t) => {
  process.env.AI_IMAGE_PROVIDER_ORDER = 'deepseek';
  process.env.AI_RETRY_LIMIT = '3';
  const post = t.mock.method(axios, 'post', async () => ({
    data: {
      choices: [{
        finish_reason: 'length',
        message: { content: '', reasoning_content: 'unfinished' },
      }],
    },
  }));
  await assert.rejects(callAiWithImage('test-image', 'en', null, true), /finish_reason=length/);
  assert.equal(post.mock.callCount(), 1);
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

test('simultaneous nutrition lookups share one call and retain each portion', async (t) => {
  const name = 'concurrent cache rice';
  let finish;
  const post = t.mock.method(axios, 'post', () => new Promise(resolve => { finish = resolve; }));
  const first = fillMissingNutrition(unresolved(name, 100));
  const second = fillMissingNutrition(unresolved(name, 250));
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(post.mock.callCount(), 1);
  finish(reply(JSON.stringify({ foods: { [name]: { calories: 160, protein_g: 10, carbs_g: 30, fat_g: 0 } } })));
  const results = await Promise.all([first, second]);
  assert.equal(results[0].totals.calories, 160);
  assert.equal(results[1].totals.calories, 400);
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

test('persisted nutrition avoids another text-model call after memory loss', async (t) => {
  const name = 'persisted cache test food';
  t.mock.method(redisCache, 'getJson', async () => ({
    calories: 160, protein: 10, carbs: 30, fat: 0,
  }));
  const post = t.mock.method(axios, 'post', async () => {
    throw new Error('the model should not be called');
  });

  const result = await fillMissingNutrition(unresolved(name, 250));
  assert.equal(result.totals.calories, 400);
  assert.equal(post.mock.callCount(), 0);
});

test('new nutrition estimates are persisted without food names in the key', async (t) => {
  const name = 'new persistent cache test food';
  t.mock.method(redisCache, 'getJson', async () => null);
  const setJson = t.mock.method(redisCache, 'setJson', async () => true);
  t.mock.method(axios, 'post', async () => reply(JSON.stringify({
    foods: { [name]: { calories: 160, protein_g: 10, carbs_g: 30, fat_g: 0 } },
  })));

  await fillMissingNutrition(unresolved(name));
  assert.equal(setJson.mock.callCount(), 1);
  const [key, value, ttl] = setJson.mock.calls[0].arguments;
  assert.ok(key.startsWith('nutrition-name:v1:'));
  assert.equal(key.includes(name), false);
  assert.equal(value.calories, 160);
  assert.equal(ttl, 30 * 24 * 60 * 60);
});
