// A food's health score, 1 (worst) to 10 (best), from what is known about it.
//
// Every v2 scan item used to be given a flat 5, so every meal read "5/10 Okay"
// whatever was on the plate. The score is now derived, per 100 g, from:
//
//  - energy density: calorie-dense foods score lower;
//  - protein share of calories: protein-rich foods score higher;
//  - a very high fat share, which scores lower;
//  - what kind of food it is. Four macros cannot tell an apple from a soda --
//    both are water and sugar -- so the kind of food decides that: fruit,
//    vegetables, legumes and nuts earn a bonus, and fried or fast food,
//    processed meat and sweets are capped however their macros look.
//
// The kind comes from the food's name first and its database category second:
// the name is the more specific of the two ("french fries" is filed under
// vegetables in the curated table), and an AI-estimated food has no category.
//
// Labels in the app: 9-10 Excellent, 7-8 Good, 5-6 Okay, 3-4 Poor, 1-2 Bad.

const BASE = 6;

const KIND_RULES = [
  // Order matters: the first kind whose words appear in the name wins, so
  // "apple pie" is a sweet before it is a fruit.
  //
  // Diet first: a diet or zero-sugar drink shares the soda's name but not its
  // sugar, and was being scored as a sugary drink.
  { kind: 'diet', words: ['diet', 'zero', 'zero sugar', 'sugar free', 'sugarfree', 'no sugar'] },
  {
    kind: 'sweet',
    words: ['soda', 'cola', 'soft drink', 'energy drink', 'lemonade', 'milkshake',
      'candy', 'chocolate', 'cake', 'cupcake', 'cookie', 'cookies', 'biscuit',
      'biscuits', 'donut', 'doughnut', 'pastry', 'brownie', 'ice cream',
      'dessert', 'syrup', 'jam', 'jelly', 'pudding', 'muffin', 'pie', 'sweets',
      'baklava', 'kunafa', 'halwa', 'gulab jamun', 'jalebi'],
  },
  { kind: 'juice', words: ['juice', 'smoothie'] },
  {
    kind: 'processed',
    words: ['sausage', 'sausages', 'bacon', 'salami', 'pepperoni', 'hot dog',
      'hotdog', 'bologna', 'ham', 'luncheon meat'],
  },
  {
    kind: 'fried',
    words: ['fries', 'chips', 'crisps', 'fried', 'deep fried', 'nuggets',
      'burger', 'cheeseburger', 'pizza', 'onion rings', 'tempura', 'samosa',
      'pakora', 'battered', 'breaded'],
  },
  {
    kind: 'nuts',
    words: ['nuts', 'nut', 'almond', 'almonds', 'walnut', 'walnuts', 'peanut',
      'peanuts', 'cashew', 'cashews', 'pistachio', 'pistachios', 'seeds'],
  },
  {
    kind: 'legumes',
    words: ['beans', 'lentil', 'lentils', 'dal', 'daal', 'chickpea', 'chickpeas',
      'hummus', 'edamame', 'peas'],
  },
  {
    kind: 'produce',
    words: ['salad', 'vegetable', 'vegetables', 'broccoli', 'spinach', 'kale',
      'lettuce', 'cucumber', 'tomato', 'tomatoes', 'carrot', 'carrots',
      'pepper', 'peppers', 'cabbage', 'cauliflower', 'zucchini', 'fruit',
      'apple', 'apples', 'banana', 'bananas', 'orange', 'oranges', 'berries',
      'strawberry', 'strawberries', 'blueberries', 'grapes', 'melon',
      'watermelon', 'mango', 'pear', 'peach', 'pineapple', 'kiwi', 'dates'],
  },
];

const CATEGORY_KINDS = {
  'vegetables and vegetable products': 'produce',
  vegetables: 'produce',
  'fruits and fruit juices': 'produce',
  fruits: 'produce',
  'legumes and legume products': 'legumes',
  legumes_nuts: 'legumes',
  'nut and seed products': 'nuts',
  sweets: 'sweet',
  desserts: 'sweet',
  'fast foods': 'fried',
  fast_food: 'fried',
  snacks: 'fried',
  'sausages and luncheon meats': 'processed',
};

const DRINK_CATEGORIES = new Set(['beverages', 'drinks']);

function normalizeName(name) {
  return ` ${String(name || '').toLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim()} `;
}

function kindFromName(name) {
  const text = normalizeName(name);
  for (const rule of KIND_RULES) {
    if (rule.words.some((word) => text.includes(` ${word} `))) return rule.kind;
  }
  return null;
}

function kindOf({ name, category, per100g }) {
  const named = kindFromName(name);
  if (named) return named;
  const cat = String(category || '').toLowerCase();
  if (CATEGORY_KINDS[cat]) return CATEGORY_KINDS[cat];
  // A drink that is almost all sugar is a soft drink, whatever it is called.
  if (DRINK_CATEGORIES.has(cat) && per100g.calories > 20 &&
      (per100g.carbs * 4) / per100g.calories > 0.85) {
    return 'sweet';
  }
  return null;
}

/// Health score for one food. Returns null when there is no nutrition to judge.
function healthScoreFor({ per100g, category = null, name = '' } = {}) {
  if (!per100g) return null;
  const calories = Math.max(0, Number(per100g.calories) || 0);
  const protein = Math.max(0, Number(per100g.protein) || 0);
  const carbs = Math.max(0, Number(per100g.carbs) || 0);
  const fat = Math.max(0, Number(per100g.fat) || 0);
  const values = { calories, protein, carbs, fat };

  let score = BASE;

  if (calories <= 60) score += 2;
  else if (calories <= 120) score += 1;
  else if (calories <= 200) score += 0;
  else if (calories <= 300) score -= 1;
  else if (calories <= 450) score -= 2;
  else score -= 3;

  // Shares are only meaningful once there is some energy to share out; water
  // and cucumber should not be marked down for lacking protein.
  if (calories > 40) {
    const proteinShare = (protein * 4) / calories;
    if (proteinShare >= 0.3) score += 2;
    else if (proteinShare >= 0.18) score += 1;
    else if (proteinShare < 0.06) score -= 1;
  }
  if (calories > 100 && (fat * 9) / calories > 0.6) score -= 1;

  let cap = 10;
  switch (kindOf({ name, category, per100g: values })) {
    case 'produce': score += 2; break;
    case 'legumes': score += 1; break;
    case 'nuts': score += 3; break;
    case 'diet': cap = 5; break;
    case 'juice': cap = 5; break;
    case 'fried': cap = 4; break;
    case 'processed': cap = 4; break;
    case 'sweet': score -= 3; cap = 2; break;
    default: break;
  }

  return Math.max(1, Math.min(cap, Math.round(score)));
}

module.exports = { healthScoreFor, kindOf };
