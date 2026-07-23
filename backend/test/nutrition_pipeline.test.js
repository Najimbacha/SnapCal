const assert = require('node:assert');
const test = require('node:test');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';
process.env.NODE_ENV = 'test';

const { calculateNutrition, enrichScanResults, getV2SystemPrompt } = require('../server');

test('calculateNutrition computes correct values from per100g and weight', () => {
  const per100g = { calories: 165, protein: 31, carbs: 0, fat: 3.6 };
  const result = calculateNutrition(per100g, 180);
  assert.equal(result.calories, 297);
  assert.equal(result.protein, 55.8);
  assert.equal(result.carbs, 0);
  assert.equal(result.fat, 6.5);
});

test('calculateNutrition handles zero weight gracefully', () => {
  const per100g = { calories: 165, protein: 31, carbs: 0, fat: 3.6 };
  const result = calculateNutrition(per100g, 0);
  assert.equal(result.calories, 0);
  assert.equal(result.protein, 0);
  assert.equal(result.carbs, 0);
  assert.equal(result.fat, 0);
});

test('enrichScanResults returns matched item for known food', () => {
  const foods = [{ name: 'chicken breast', estimated_weight_g: 180, confidence: 0.96 }];
  const result = enrichScanResults(foods);
  assert.equal(result.items.length, 1);
  assert.equal(result.items[0].matched, true);
  assert.equal(result.items[0].nutrition_match_id, 'FDB_000003');
  assert.equal(result.items[0].calories, 297);
  assert.equal(result.items[0].nutrition.actual.calories, 297);
  assert.equal(result.items[0].nutrition.per100g.calories, 165);
  assert.equal(result.totals.calories, 297);
});

test('enrichScanResults returns unmatched item for unknown food', () => {
  const foods = [{ name: 'purple unicorn meat', estimated_weight_g: 100, confidence: 0.5 }];
  const result = enrichScanResults(foods);
  assert.equal(result.items.length, 1);
  assert.equal(result.items[0].matched, false);
  assert.equal(result.items[0].nutrition_match_id, null);
  assert.equal(result.items[0].calories, null);
  assert.equal(result.items[0].protein, null);
  assert.equal(result.items[0].nutrition, null);
  assert.equal(result.totals.calories, 0);
});

test('enrichScanResults totals exclude unmatched foods', () => {
  const foods = [
    { name: 'chicken breast', estimated_weight_g: 180, confidence: 0.96 },
    { name: 'white rice', estimated_weight_g: 200, confidence: 0.94 },
    { name: 'unknown mystery goo', estimated_weight_g: 30, confidence: 0.3 },
  ];
  const result = enrichScanResults(foods);
  assert.equal(result.items.length, 3);
  assert.equal(result.items[0].matched, true);
  assert.equal(result.items[1].matched, true);
  assert.equal(result.items[2].matched, false);
  assert.equal(result.totals.calories, result.items[0].nutrition.actual.calories + result.items[1].nutrition.actual.calories);
  assert.ok(result.totals.calories > 0);
});

test('enrichScanResults throws on empty foods array', () => {
  assert.throws(() => enrichScanResults([]), /empty-food-detection/);
  assert.throws(() => enrichScanResults(null), /empty-food-detection/);
});

test('enrichScanResults handles mixed confidence and multiple items', () => {
  const foods = [
    { name: 'broccoli', estimated_weight_g: 100, confidence: 0.95 },
    { name: 'olive oil', estimated_weight_g: 15, confidence: 0.65 },
  ];
  const result = enrichScanResults(foods);

  assert.equal(result.items[0].food_name, 'broccoli');
  assert.equal(result.items[0].confidence, 0.95);
  assert.equal(result.items[0].matched, true);

  assert.equal(result.items[1].food_name, 'olive oil');
  assert.equal(result.items[1].confidence, 0.65);
  assert.equal(result.items[1].matched, true);

  const expectedTotal = result.items[0].nutrition.actual.calories + result.items[1].nutrition.actual.calories;
  assert.equal(result.totals.calories, expectedTotal);
});

test('v2 system prompt does not ask AI to provide nutrition values', () => {
  const prompt = getV2SystemPrompt('en');
  assert.ok(prompt.includes('Do NOT calculate'));
  assert.ok(prompt.includes('Do NOT provide health scores'));
  const returnJson = prompt.substring(prompt.indexOf('Return'));
  assert.ok(!returnJson.includes('calories'));
  assert.ok(!returnJson.includes('protein'));
  assert.ok(!returnJson.includes('carbs'));
  assert.ok(!returnJson.includes('fat'));
  assert.ok(!returnJson.includes('health_score'));
  assert.ok(!returnJson.includes('insights'));
  assert.ok(!returnJson.includes('alternatives'));
});

test('v2 system prompt mentions foods, name, estimated_weight_g, and confidence', () => {
  const prompt = getV2SystemPrompt('en');
  assert.ok(prompt.includes('"foods"'));
  assert.ok(prompt.includes('"name"'));
  assert.ok(prompt.includes('"estimated_weight_g"'));
  assert.ok(prompt.includes('"confidence"'));
});

test('v2 system prompt supports Arabic language', () => {
  const prompt = getV2SystemPrompt('ar');
  assert.ok(prompt.includes('Arabic'));
  assert.ok(prompt.includes('"foods"'));
});
