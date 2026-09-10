const assert = require('node:assert');
const test = require('node:test');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';

const provider = require('../services/providers/local_json_provider');
const { healthScoreFor } = require('../services/health_score');
const { getV2SystemPrompt } = require('../server');

// "yellow rice" matched the dry seasoning mix at 343 kcal/100 g, and a 300 g
// plate of rice came to 1,029 kcal.
test('rice on a plate never resolves to a dry mix or uncooked grain', () => {
  for (const name of ['yellow rice', 'rice', 'white rice', 'brown rice', 'pasta', 'black beans']) {
    const match = provider.lookup(name);
    assert.ok(
      match === null || match.per100g.calories < 250,
      `${name} matched ${match && match.displayName} at ${match && match.per100g.calories} kcal/100g`,
    );
  }
});

test('a name that asks for the dry or raw form still gets it', () => {
  const lentils = provider.lookup('raw lentils');
  assert.ok(lentils, 'raw lentils should still match');
  assert.ok(lentils.per100g.calories > 300, `raw lentils ${lentils.per100g.calories}`);
});

// With the dry mix skipped, the prepared 'Rice and vermicelli mix, chicken
// flavor' was left to answer 'chicken with rice': rice with no chicken in it.
test('a food borrowed only as a flavour is not that food', () => {
  const match = provider.lookup('chicken with rice');
  assert.ok(!match || !/flavor/i.test(match.displayName), `chicken with rice matched ${match && match.displayName}`);
});

test('foods eaten raw are untouched', () => {
  assert.ok(provider.lookup('almonds'), 'almonds');
  assert.ok(provider.lookup('cucumber'), 'cucumber');
});

// A Diet Pepsi can was scored as regular Pepsi: 135 kcal instead of about 2.
test('brand-name colas find the right row', () => {
  assert.equal(provider.lookup('pepsi').displayName, 'Cola soda');
  for (const name of ['diet pepsi', 'pepsi max', 'coke zero', 'zero sugar cola']) {
    const match = provider.lookup(name);
    assert.equal(match && match.displayName, 'Diet cola soda', name);
  }
});

test('the scan prompt reads DIET and ZERO off the label and uses the product, not the brand', () => {
  const prompt = getV2SystemPrompt('en');
  assert.ok(prompt.includes('DIET, ZERO, LIGHT, SUGAR FREE'));
  assert.ok(prompt.includes('match_key "diet cola"'));
  assert.ok(prompt.includes('rice, pasta and grains are cooked'));
});

test('a diet drink is not scored as a sugary one', () => {
  const diet = healthScoreFor({ name: 'diet cola', per100g: { calories: 1, protein: 0, carbs: 0, fat: 0 } });
  const regular = healthScoreFor({ name: 'cola', per100g: { calories: 41, protein: 0, carbs: 10.6, fat: 0 } });
  assert.ok(diet >= 5, `diet cola ${diet}`);
  assert.ok(regular <= 2, `cola ${regular}`);
});

// Cooking drives water out of meat, fish, eggs and potatoes: a raw row runs a
// quarter to a third low on a cooked plate. Those foods resolve to a cooked
// row or to none, whatever name the scan uses.
test('meat, fish, eggs and potatoes never resolve to a raw row', () => {
  for (const name of [
    'chicken', 'chicken breast', 'beef', 'steak', 'ground beef', 'ground lamb',
    'lamb', 'pork', 'salmon', 'cod', 'shrimp', 'egg', 'eggs', 'potato',
    'russet potatoes', 'sweet potato', 'turkey', 'duck', 'chicken liver',
  ]) {
    const match = provider.lookup(name);
    assert.ok(!match || !/\braw\b/i.test(match.displayName), `${name} matched ${match && match.displayName}`);
  }
  assert.match(provider.lookup('ground lamb').displayName, /cooked/i);
});

test('fruit, vegetables, nuts and raw dishes keep their raw rows', () => {
  for (const name of ['banana', 'apple', 'tomato', 'cucumber', 'almonds']) {
    assert.match(provider.lookup(name).displayName, /\braw\b/i, name);
  }
  assert.ok(provider.lookup('sashimi'), 'sashimi');
  assert.ok(provider.lookup('sushi'), 'sushi');
});
