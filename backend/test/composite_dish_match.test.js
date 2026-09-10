const assert = require('node:assert');
const test = require('node:test');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';

const provider = require('../services/providers/local_json_provider');
const { enrichScanResults, getV2SystemPrompt } = require('../server');

// A plate of grilled chicken and rice was matched to the "grilled chicken" row
// and scaled to the plate's weight: 176 g of protein and 0 g of carbohydrate.
test('a dish joining two foods is not matched to just one of them', () => {
  for (const name of [
    'grilled chicken with rice',
    'rice with grilled chicken',
    'grilled chicken and rice',
    'grilled chicken with rice and fries',
  ]) {
    const match = provider.lookup(name);
    assert.ok(
      match === null || match.per100g.carbs > 0,
      `${name} matched ${match && match.displayName}`,
    );
  }
});

test('single foods and named dishes still match as before', () => {
  assert.equal(provider.lookup('grilled chicken').displayName, 'Chicken, grilled');
  assert.equal(provider.lookup('grilled chicken breast')?.per100g.carbs, 0);
  assert.equal(provider.lookup('chicken mandi').displayName, 'Mandi, chicken');
  assert.ok(provider.lookup('french fries'), 'french fries should match');
});

test('an unmatched composite dish is left for a whole-dish estimate, not zeroed', () => {
  const { items } = enrichScanResults([{
    name: 'Grilled Chicken with Rice',
    match_key: 'grilled chicken with rice',
    estimated_weight_g: 550,
    confidence: 0.87,
  }]);
  assert.equal(items[0].matched, false);
  // fillMissingNutrition estimates 'unresolved' items from the dish name.
  assert.equal(items[0].nutrition_source, 'unresolved');
});

// The model returned "grilled chicken with rice" as one item for a plate that
// also held fries. Separate foods are listed separately now, which lets each
// one find its own row; only dishes cooked as one stay whole.
test('the scan prompt splits separate foods on one plate and keeps cooked dishes whole', () => {
  const prompt = getV2SystemPrompt('en');
  assert.ok(prompt.includes('even on the same plate'));
  assert.ok(prompt.includes('grilled chicken, rice and fries on one plate = three items'));
  assert.ok(prompt.includes('chicken mandi'));
  assert.ok(prompt.includes('Never join foods with "with" or "and"'));
});
