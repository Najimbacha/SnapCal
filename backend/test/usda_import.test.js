const test = require('node:test');
const assert = require('node:assert');

process.env.NODE_ENV = 'test';

const { shortAlias, toRow } = require('../scripts/import-usda.js');

// USDA descriptions put the food first and qualify it afterwards, which is
// why a naive import produces aliases nothing can match.
test('a short alias keeps the cut and the preparation', () => {
  assert.strictEqual(
    shortAlias('Chicken, broilers or fryers, breast, meat only, cooked, roasted'),
    'chicken breast roasted',
  );
});

test('preparation is what separates two otherwise identical rows', () => {
  // These differ by roughly double the calories. If both collapsed to
  // "chicken breast" the matcher would be choosing between them at random.
  const roasted = shortAlias('Chicken, broilers or fryers, breast, meat only, cooked, roasted');
  const fried = shortAlias('Chicken, broilers or fryers, breast, meat and skin, cooked, fried, batter');
  assert.notStrictEqual(roasted, fried);
  assert.ok(fried.includes('fried'));
});

test('the last preparation wins, being the specific one', () => {
  // "cooked, hard-boiled" is a boiled egg; "cooked" alone says nothing.
  assert.ok(shortAlias('Egg, whole, cooked, hard-boiled').includes('boiled'));
});

test('livestock and grading vocabulary is dropped, not treated as the food', () => {
  const alias = shortAlias('Beef, ground, 80% lean meat / 20% fat, patty, cooked, broiled');
  assert.ok(alias.startsWith('beef'));
  for (const noise of ['broilers', 'fryers', 'separable', 'lean', 'select', 'choice']) {
    assert.ok(!alias.includes(noise), `"${noise}" should not survive into "${alias}"`);
  }
});

test('a description with nothing usable yields no alias rather than junk', () => {
  assert.strictEqual(shortAlias(''), null);
  assert.strictEqual(shortAlias(',,,'), null);
});

// ── Row extraction ──────────────────────────────────────────────────────────

function usdaFood(nutrients, description = 'Test food, raw') {
  return {
    fdcId: 12345,
    description,
    foodCategory: { description: 'Test Category' },
    foodNutrients: Object.entries(nutrients).map(([id, amount]) => ({
      nutrient: { id: Number(id) },
      amount,
    })),
  };
}

test('reads energy and the three macros by nutrient id', () => {
  const parsed = toRow(usdaFood({ 1008: 165, 1003: 31.02, 1005: 0, 1004: 3.57 }));
  assert.deepStrictEqual(
    { ...parsed.row, display_name: undefined, category: undefined, fdc_id: undefined },
    { display_name: undefined, calories: 165, protein: 31, carbs: 0, fat: 3.6,
      category: undefined, source: 'usda', fdc_id: undefined },
  );
});

test('a food with no energy figure is skipped, not imported as zero', () => {
  // Importing it as zero would recreate exactly the bug this whole change is
  // about: a confident-looking row worth nothing.
  assert.strictEqual(toRow(usdaFood({ 1003: 10 })), null);
});

test('impossible values are treated as a parsing fault', () => {
  assert.strictEqual(toRow(usdaFood({ 1008: 4000, 1003: 1, 1005: 1, 1004: 1 })), null);
  assert.strictEqual(toRow(usdaFood({ 1008: 200, 1003: 400, 1005: 1, 1004: 1 })), null);
  assert.strictEqual(toRow(usdaFood({ 1008: 100, 1003: -5, 1005: 1, 1004: 1 })), null);
});

test('missing macros default to zero but energy must be real', () => {
  const parsed = toRow(usdaFood({ 1008: 884, 1004: 100 }, 'Oil, olive, salad or cooking'));
  assert.strictEqual(parsed.row.calories, 884);
  assert.strictEqual(parsed.row.protein, 0);
  assert.strictEqual(parsed.alias, 'oil olive');
});

test('a row with no description cannot be aliased and is skipped', () => {
  assert.strictEqual(toRow(usdaFood({ 1008: 100 }, '')), null);
});

// ── The matcher, once the table is large ────────────────────────────────────

const provider = require('../services/providers/local_json_provider');

test('the curated table still resolves what it always did', () => {
  // Guards against the ambiguity margin quietly turning good matches into
  // misses. These all worked before it existed.
  for (const [query, expected] of [
    ['chicken breast', 'Chicken breast, roasted'],
    ['white rice', 'White rice, cooked'],
    ['grandmothers chicken curry', 'Chicken curry'],
  ]) {
    const match = provider.lookup(query);
    assert.ok(match, `"${query}" should still match`);
    assert.strictEqual(match.displayName, expected);
  }
});

test('a food genuinely absent is still a clean miss', () => {
  assert.strictEqual(provider.lookup('turkish simit pastry'), null);
  assert.strictEqual(provider.lookup(''), null);
  assert.strictEqual(provider.lookup(null), null);
});

test('preparation still disqualifies the opposite preparation', () => {
  // A fried food must never resolve to the roasted row: frying roughly
  // doubles the energy, so it is a different food in the only sense that
  // matters here.
  const fried = provider.lookup('fried chicken breast');
  if (fried) assert.ok(!/roasted/i.test(fried.displayName));
});
