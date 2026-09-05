const test = require('node:test');
const assert = require('node:assert/strict');
const { buildImport, toRow, normalize } = require('../scripts/import-usda');
const provider = require('../services/providers/local_json_provider');
const db = require('../data/nutrition_db.json');
const aliases = require('../data/usda_aliases.json');

function food(id, description, nutrients = {}, dataType = 'SR Legacy') {
  return { fdcId: id, description, dataType,
    foodNutrients: Object.entries({ 1008: 120, 1003: 3, 1004: 2, 1005: 22, ...nutrients })
      .map(([id, amount]) => ({ nutrient: { id: Number(id) }, amount })) };
}

test('Foundation specific energy takes precedence, then standard, then general', () => {
  assert.equal(toRow(food(1, 'A', { 2048: 117, 2047: 121 })).row.calories, 117);
  assert.equal(toRow(food(1, 'A', { 2047: 121 })).row.calories, 120);
  assert.equal(toRow(food(1, 'A', { 1008: null, 2047: 121 })).row.calories, 121);
  assert.equal(toRow(food(1, 'A', { 1003: null })), null);
});

test('invalid units and null records cannot become nutrition', () => {
  const input = food(1, 'A');
  input.foodNutrients.find(n => n.nutrient.id === 1008).nutrient.unitName = 'kJ';
  assert.equal(toRow(input), null);
  assert.equal(toRow(null), null);
  assert.equal(toRow(food(-1, 'A')), null);
});

test('zero-calorie food is accepted only with complete explicit zeros', () => {
  assert.equal(toRow(food(1, 'Water', { 1008: 0, 1003: 0, 1004: 0, 1005: 0 })).row.calories, 0);
});

test('colliding full names retain both USDA IDs and reimport is stable', () => {
  const foods = [food(1, 'Rice, cooked'), food(2, 'Rice, cooked', { 1008: 150 })];
  const first = buildImport({}, foods);
  assert.deepEqual(first.aliases['rice cooked'], ['USDA_1', 'USDA_2']);
  const second = buildImport(first.db, [...foods, foods[0]]);
  assert.deepEqual(second.db, first.db);
  assert.deepEqual(second.aliases, first.aliases);
  assert.equal(second.report.duplicateIds.length, 1);
  assert.throws(() => buildImport({}, [foods[0], food(1, 'Rice, raw')]), /Conflicting/);
});

test('mapping requires both reviewed identities and preserves the old ID', () => {
  const original = { FDB_1: { display_name: 'Rice', calories: 99, category: 'grains' } };
  const map = [{ id: 'FDB_1', fdc_id: 1, expected_name: 'Rice', usda_description: 'Rice, cooked' }];
  const result = buildImport(original, [food(1, 'Rice, cooked')], map);
  assert.equal(result.db.FDB_1.calories, 120);
  assert.equal(result.db.FDB_1.display_name, 'Rice');
  assert.equal(result.db.FDB_1.category, 'grains');
  assert.equal(original.FDB_1.calories, 99);
  assert.throws(() => buildImport(original, [food(1, 'Rice, raw')], map), /no longer matches/);
});

test('preparation, skin and milkfat conflicts are rejected', () => {
  for (const [query, name] of [
    ['rice raw', 'Rice, cooked'], ['rice cooked', 'Rice, raw'],
    ['fried chicken', 'Chicken, roasted'],
    ['chicken skinless', 'Chicken, meat and skin, cooked'],
    ['milk 1%', 'Milk, 2% milkfat'],
    ['milk unsweetened', 'Milk, sweetened'],
    ['extra virgin olive oil', 'Oil, olive, salad or cooking'],
  ]) assert.equal(provider.compatible(query, name), false, query);
});

test('Foundation wins only for the same full food identity', () => {
  const rows = {
    a: { display_name: 'Milk, whole', dataset: 'SR Legacy' },
    b: { display_name: 'Milk, whole', dataset: 'Foundation' },
    c: { display_name: 'Milk, skim', dataset: 'Foundation' },
  };
  const candidates = Object.keys(rows).map(id => ({ id, score: 1 }));
  assert.deepEqual(provider.selectPreferredSources(candidates, rows).map(x => x.id), ['b', 'c']);
});

test('all imported records have complete finite nutrients and resolvable IDs', () => {
  const imported = Object.entries(db).filter(([id]) => id.startsWith('USDA_'));
  assert.ok(imported.length > 8000);
  for (const [id, row] of imported) {
    assert.equal(id, 'USDA_' + row.fdc_id);
    for (const name of ['calories', 'protein', 'carbs', 'fat']) assert.ok(Number.isFinite(row[name]), id);
    assert.deepEqual(provider.getFoodById(id).per100g,
      { calories: row.calories, protein: row.protein, carbs: row.carbs, fat: row.fat });
  }
  for (const ids of Object.values(aliases)) for (const id of ids) assert.ok(db[id], id);
});

test('new ambiguous exact alias cannot pick the first food', () => {
  const curated = require('../data/food_aliases.json');
  const collision = Object.entries(aliases).find(([name, ids]) => !curated[name] &&
    ids.length > 1 && new Set(ids.map(id => normalize(db[id].display_name))).size > 1 &&
    ids.every(id => provider.compatible(name, db[id].display_name)));
  assert.ok(collision);
  assert.equal(provider.lookup(collision[0]), null);
});

test('reference USDA foods retain source values and match full descriptions', () => {
  for (const [id, kcal] of [[168878, 130], [171413, 884], [171477, 165], [173424, 155]]) {
    const row = db['USDA_' + id];
    assert.equal(row.calories, kcal);
    const match = provider.lookup(row.display_name);
    assert.ok(match, row.display_name);
    assert.equal(match.per100g.calories, kcal);
  }
});

test('shared modifiers do not turn milk into ice cream', () => {
  assert.equal(provider.lookup('fat free milk').displayName, 'Skim milk');
  assert.equal(provider.lookup('nonfat milk').displayName, 'Skim milk');
  const match = provider.lookup('unsweetened milk beverage');
  if (match) assert.ok(/milk/i.test(match.displayName));
});

test('known aliases survive while fried eggs use their actual preparation', () => {
  assert.equal(provider.lookup('dried grapes').displayName, 'Raisins');
  assert.equal(provider.lookup('grilled salmon').displayName, 'Salmon, cooked');
  const fried = provider.lookup('fried egg');
  assert.equal(fried.displayName, 'Egg, whole, cooked, fried');
  assert.equal(fried.per100g.calories, 196);
});
