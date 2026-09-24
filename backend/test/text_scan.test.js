const test = require('node:test');
const assert = require('node:assert');

process.env.NODE_ENV = 'test';

const {
  getTextMealPrompt,
  parseTextMealDetection,
  enrichScanResults,
} = require('../server');

test('voice meal prompt treats the transcript as data and requests the scan shape', () => {
  const prompt = getTextMealPrompt('ar', 'بيضتان وقطعة خبز');

  assert.match(prompt, /untrusted user data/);
  assert.match(prompt, /"foods"/);
  assert.match(prompt, /"match_key"/);
  assert.match(prompt, /Arabic/);
  assert.match(prompt, /بيضتان وقطعة خبز/);
  assert.doesNotMatch(prompt, /calories.*number/);
});

test('voice meal detection is bounded and normalized before nutrition matching', () => {
  const foods = parseTextMealDetection(JSON.stringify({
    foods: [
      {
        name: 'Two eggs',
        match_key: 'boiled egg',
        estimated_weight_g: 110.4,
        confidence: 9,
      },
      { name: '', match_key: 'ignored' },
      { name: 'Tea', estimated_weight_g: -20 },
    ],
  }));

  assert.deepEqual(foods, [
    {
      name: 'Two eggs',
      match_key: 'boiled egg',
      estimated_weight_g: 110,
      confidence: 1,
    },
    { name: 'Tea', match_key: 'Tea', confidence: 0.5 },
  ]);

  const result = enrichScanResults(foods);
  assert.equal(result.items.length, 2);
  assert.equal(result.items[0].food_name, 'Two eggs');
  assert.equal(result.items[0].weight_g, 110);
});

test('voice meal detection accepts fenced JSON and caps the item count', () => {
  const manyFoods = Array.from({ length: 25 }, (_, index) => ({
    name: `Food ${index}`,
    match_key: `food ${index}`,
    estimated_weight_g: 100,
    confidence: 0.8,
  }));

  const parsed = parseTextMealDetection(
    `Here is the result:\n\`\`\`json\n${JSON.stringify({ foods: manyFoods })}\n\`\`\``,
  );
  assert.equal(parsed.length, 20);
});
