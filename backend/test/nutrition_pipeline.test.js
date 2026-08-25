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

// ── Accuracy guards added with the Atwater gate / scored matcher work ────────

const { reconcileNutrition, normalizeNutrition } = require('../server');
const provider = require('../services/providers/local_json_provider');

test('reconcileNutrition accepts a self-consistent macro set', () => {
  // 31g protein + 0g carbs + 3.6g fat = 156 kcal against a stated 165.
  const r = reconcileNutrition({ calories: 165, protein: 31, carbs: 0, fat: 3.6 });
  assert.equal(r.ok, true);
});

test('reconcileNutrition flags a contradictory macro set', () => {
  // 10*4 + 20*4 + 5*9 = 165 kcal, stated as 400 — a 2.4x contradiction that
  // clamping alone could never catch.
  const r = reconcileNutrition({ calories: 400, protein: 10, carbs: 20, fat: 5 });
  assert.equal(r.ok, false);
  assert.ok(r.ratio < 0.5);
});

test('reconcileNutrition tolerates near-zero foods', () => {
  assert.equal(reconcileNutrition({ calories: 1, protein: 0, carbs: 0, fat: 0 }).ok, true);
  assert.equal(reconcileNutrition({ calories: 2, protein: 0, carbs: 0, fat: 0 }).ok, true);
});

test('normalizeNutrition attaches a reconciliation flag to every item', () => {
  const raw = JSON.stringify({
    items: [{ food_name: 'Mystery', portion: '1 plate', calories: 400, protein: 10, carbs: 20, fat: 5 }],
  });
  const out = normalizeNutrition(raw);
  assert.equal(out.items[0].nutrition_flag, 'inconsistent');
  assert.equal(out.items[0].nutrition_source, 'ai_estimate');
});

test('matcher does not resolve a fried food to a lean preparation', () => {
  const lean = provider.lookup('grilled chicken breast');
  const fried = provider.lookup('fried chicken');
  assert.ok(lean, 'grilled chicken breast should still match');
  // Whatever "fried chicken" resolves to, it must not be the lean entry.
  if (fried) {
    assert.notEqual(fried.id, lean.id);
    assert.ok(fried.per100g.calories > lean.per100g.calories);
  }
});

test('matcher refuses a single weak shared word', () => {
  // Previously resolved to "Chicken breast, roasted" via the word "chicken".
  assert.equal(provider.lookup('chicken salad'), null);
});

test('matcher still honours exact aliases', () => {
  assert.ok(provider.lookup('chicken breast'));
  assert.ok(provider.lookup('white rice'));
  assert.ok(provider.lookup('broccoli'));
});

test('normalize preserves non-Latin scripts', () => {
  assert.equal(provider.normalize('دجاج مشوي'), 'دجاج مشوي');
  assert.equal(provider.normalize('Poulet Grillé'), 'poulet grille');
  assert.equal(provider.normalize('Chicken, roasted (skinless)'), 'chicken roasted skinless');
});

test('enrichScanResults looks up by English match_key, displays localised name', () => {
  const result = enrichScanResults([
    { name: 'دجاج مشوي', match_key: 'chicken breast', estimated_weight_g: 180, confidence: 0.9 },
  ]);
  assert.equal(result.items[0].matched, true);
  assert.equal(result.items[0].food_name, 'دجاج مشوي');
  assert.equal(result.items[0].nutrition_match_id, 'FDB_000003');
  assert.equal(result.items[0].calories, 297);
});

test('enrichScanResults treats a missing weight as unknown, not zero', () => {
  const result = enrichScanResults([
    { name: 'chicken breast', confidence: 0.9 },
  ]);
  const item = result.items[0];
  assert.equal(item.matched, false);
  assert.equal(item.portion, 'Unknown');
  assert.equal(item.calories, null);
  assert.equal(item.nutrition_flag, 'unmatched');
});

test('enrichScanResults reports the database row it used', () => {
  const result = enrichScanResults([
    { name: 'chicken breast', estimated_weight_g: 100, confidence: 0.9 },
  ]);
  assert.equal(result.items[0].matched_name, 'Chicken breast, roasted');
  assert.equal(result.items[0].nutrition_source, 'database');
  assert.equal(result.items[0].nutrition_flag, 'ok');
});

test('v2 prompt requests an English match_key', () => {
  const prompt = getV2SystemPrompt('ar');
  assert.ok(prompt.includes('"match_key"'));
  assert.ok(prompt.includes('ENGLISH'));
});
