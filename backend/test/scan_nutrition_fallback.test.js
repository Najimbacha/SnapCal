const test = require('node:test');
const assert = require('node:assert');

// Before requiring the server: keeps the unmatched-food logger from reaching
// for Firestore, which has no project id here and would sit retrying.
process.env.NODE_ENV = 'test';

const {
  enrichScanResults,
  normalizePer100g,
  reconcilePer100g,
} = require('../server');

// A food the 285-row table does not have. Verified against the real
// provider: "grandmothers chicken curry" DOES match (to "Chicken curry"),
// which is correct behaviour and no use as a miss.
const UNKNOWN = 'turkish simit pastry';

function detect(extra = {}) {
  return {
    name: 'Chicken curry',
    match_key: UNKNOWN,
    estimated_weight_g: 250,
    confidence: 0.7,
    per_100g: { calories: 150, protein_g: 12, carbs_g: 6, fat_g: 8.5 },
    ...extra,
  };
}

test('an unmatched food now carries real numbers instead of nulls', () => {
  const { items } = enrichScanResults([detect()]);
  const item = items[0];

  assert.strictEqual(item.matched, false, 'not in the curated table');
  assert.strictEqual(item.nutrition_source, 'ai_estimate');
  assert.notStrictEqual(item.calories, null, 'this used to be null');
  // 150 kcal/100g at 250g
  assert.strictEqual(item.calories, 375);
  assert.strictEqual(item.protein, 30);
  assert.strictEqual(item.carbs, 15);
  assert.strictEqual(item.fat, 21.3);
});

test('per-100g travels with the item so the weight slider can rescale it', () => {
  const { items } = enrichScanResults([detect()]);
  // Without this the client cannot recompute when the user corrects the
  // portion -- which is why unmatched items had a separate, un-adjustable
  // branch in the result card.
  assert.deepStrictEqual(items[0].nutrition.per100g, {
    calories: 150,
    protein: 12,
    carbs: 6,
    fat: 8.5,
  });
});

test('a missing weight assumes 100g and says so, rather than giving up', () => {
  const { items } = enrichScanResults([detect({ estimated_weight_g: 0 })]);
  const item = items[0];
  assert.strictEqual(item.weight_g, 100);
  assert.strictEqual(item.weight_estimated, true);
  assert.strictEqual(item.calories, 150, 'priced at the assumed 100g');
});

test('a real weight is not flagged as estimated', () => {
  const { items } = enrichScanResults([detect()]);
  assert.strictEqual(items[0].weight_estimated, false);
});

test('macros that contradict the calories are rebuilt from the macros', () => {
  // The turkey sausage case from production: 300 kcal stated, macros that
  // describe 40 kcal of food.
  const { items } = enrichScanResults([
    detect({ per_100g: { calories: 300, protein_g: 10, carbs_g: 0, fat_g: 0 } }),
  ]);
  const item = items[0];
  assert.strictEqual(item.nutrition_adjusted, true);
  // 10*4 = 40 kcal/100g, at 250g = 100
  assert.strictEqual(item.nutrition.per100g.calories, 40);
  assert.strictEqual(item.calories, 100);
  assert.strictEqual(item.nutrition_flag, 'ok', 'consistent after the rebuild');
});

test('nothing usable from the model is still honestly unresolved', () => {
  const { items } = enrichScanResults([detect({ per_100g: null })]);
  const item = items[0];
  assert.strictEqual(item.nutrition_source, 'unresolved');
  assert.strictEqual(item.calories, null, 'inventing a number here would be a lie');
  assert.strictEqual(item.nutrition_flag, 'unresolved');
});

test('a food in the curated table still wins over the model', () => {
  // The model is deliberately wrong here; the database value must survive.
  const { items } = enrichScanResults([
    {
      name: 'Chicken curry',
      match_key: 'chicken curry',
      estimated_weight_g: 100,
      confidence: 0.9,
      per_100g: { calories: 900, protein_g: 1, carbs_g: 1, fat_g: 99 },
    },
  ]);
  const item = items[0];
  assert.strictEqual(item.matched, true, 'chicken curry is in the table');
  assert.strictEqual(item.nutrition_source, 'database');
  assert.notStrictEqual(item.calories, 900, 'the model must not override the table');
  assert.ok(item.calories < 400, `database value expected, got ${item.calories}`);
});

test('normalizePer100g rejects junk and clamps the impossible', () => {
  assert.strictEqual(normalizePer100g(null), null);
  assert.strictEqual(normalizePer100g({}), null);
  assert.strictEqual(normalizePer100g({ calories: 'lots' }), null);
  assert.strictEqual(
    normalizePer100g({ calories: 0, protein_g: 0, carbs_g: 0, fat_g: 0 }),
    null,
    'all zeros is the failure this whole change is about',
  );
  // 900 kcal/100g is pure fat; nothing edible exceeds it.
  const clamped = normalizePer100g({ calories: 5000, protein_g: 400, carbs_g: -3, fat_g: 12 });
  assert.strictEqual(clamped.calories, 900);
  assert.strictEqual(clamped.protein, 100);
  assert.strictEqual(clamped.carbs, 0);
});

test('reconcilePer100g leaves a consistent estimate alone', () => {
  const good = { calories: 165, protein: 31, carbs: 0, fat: 3.6 };
  const out = reconcilePer100g(good);
  assert.strictEqual(out.adjusted, false);
  assert.deepStrictEqual(out.per100g, good);
});

test('reconcilePer100g will not zero out a food whose macros are all zero', () => {
  // Black coffee: 2 kcal, no macros. Rebuilding from macros would give 0 and
  // erase a real, if tiny, value.
  const out = reconcilePer100g({ calories: 2, protein: 0, carbs: 0, fat: 0 });
  assert.strictEqual(out.per100g.calories, 2);
});
