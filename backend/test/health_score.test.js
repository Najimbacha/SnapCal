const assert = require('node:assert');
const test = require('node:test');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';

const { healthScoreFor } = require('../services/health_score');
const { enrichScanResults } = require('../server');

// Labels in the app: 9-10 Excellent, 7-8 Good, 5-6 Okay, 3-4 Poor, 1-2 Bad.
const score = (name, calories, protein, carbs, fat, category = null) =>
  healthScoreFor({ name, category, per100g: { calories, protein, carbs, fat } });

test('whole foods score well', () => {
  assert.ok(score('broccoli', 34, 2.8, 7, 0.4) >= 9, 'broccoli');
  assert.ok(score('apple', 52, 0.3, 14, 0.2) >= 9, 'apple');
  assert.ok(score('greek yogurt', 59, 10, 3.6, 0.4) >= 9, 'greek yogurt');
  assert.ok(score('lentils', 116, 9, 20, 0.4) >= 8, 'lentils');
});

test('lean protein is good, staples are okay', () => {
  const chicken = score('grilled chicken', 158, 32, 0, 3.2);
  assert.ok(chicken >= 7 && chicken <= 8, `grilled chicken ${chicken}`);
  const rice = score('white rice', 130, 2.7, 28, 0.3);
  assert.ok(rice >= 5 && rice <= 6, `white rice ${rice}`);
  const bread = score('white bread', 265, 9, 49, 3.2);
  assert.ok(bread >= 5 && bread <= 6, `white bread ${bread}`);
});

test('fried food and fast food are capped at poor', () => {
  // Filed under "vegetables" in the curated table: the name has to win.
  assert.ok(score('french fries', 312, 3.4, 38, 17, 'vegetables') <= 4, 'fries');
  assert.ok(score('cheeseburger', 263, 13, 27, 12, 'fast foods') <= 4, 'cheeseburger');
  assert.ok(score('fried chicken', 246, 19, 9, 15) <= 4, 'fried chicken');
  assert.ok(score('beef sausage', 301, 12, 2, 27) <= 4, 'sausage');
});

test('sweets and sugary drinks are bad', () => {
  // A soda and an apple have the same macros; only the kind of food differs.
  assert.ok(score('canned soda', 41, 0, 10.6, 0) <= 2, 'soda');
  assert.ok(score('chocolate cake', 371, 5, 53, 15) <= 2, 'cake');
  assert.ok(score('apple pie', 237, 2, 34, 11) <= 2, 'apple pie is a sweet first');
  assert.ok(score('orange soft drink', 48, 0, 12, 0, 'beverages') <= 2, 'drink by category');
});

test('water is fine and a food with no nutrition has no score', () => {
  assert.ok(score('water', 0, 0, 0, 0) >= 7, 'water');
  assert.equal(healthScoreFor({ name: 'mystery', per100g: null }), null);
});

// Every item used to be given a flat 5, so every meal read "5/10 Okay".
test('scan items are scored from their own nutrition', () => {
  const { items } = enrichScanResults([
    { name: 'Grilled chicken', match_key: 'grilled chicken', estimated_weight_g: 150, confidence: 0.9 },
    { name: 'French fries', match_key: 'french fries', estimated_weight_g: 120, confidence: 0.9 },
  ]);
  const [chicken, fries] = items;
  assert.ok(chicken.health_score >= 7, `chicken ${chicken.health_score}`);
  assert.ok(fries.health_score <= 4, `fries ${fries.health_score}`);
});
