const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', '..', 'data', 'nutrition_db.json');
const ALIASES_PATH = path.join(__dirname, '..', '..', 'data', 'food_aliases.json');
const USDA_ALIASES_PATH = path.join(__dirname, '..', '..', 'data', 'usda_aliases.json');

// Minimum score an inexact candidate must reach before it is accepted. Below
// this the provider returns null, so the caller falls back to "not in
// database" instead of logging a confident wrong food. A null is recoverable
// by the user; a plausible-looking wrong number is not.
const MIN_SCORE = Number(process.env.NUTRITION_MIN_MATCH_SCORE || 0.6);

// How far clear the winner must be of the best *different* food before the
// tie is treated as real ambiguity.
//
// With 285 curated rows a near-tie was rare. Importing USDA takes the table
// into the thousands, where "chicken breast" has a dozen plausible neighbours
// -- raw, roasted, with skin, canned -- and picking whichever scored a hair
// higher is a coin toss presented as a fact.
const AMBIGUITY_MARGIN = Number(process.env.NUTRITION_AMBIGUITY_MARGIN || 0.05);

// ...but a tie only matters if the answer would differ. Two rows scoring the
// same and reporting nearly the same energy are not a dilemma, they are two
// names for the same thing, and refusing there would turn common queries
// ("grilled chicken breast") into misses for no gain.
const AMBIGUITY_ENERGY_TOLERANCE = Number(
  process.env.NUTRITION_AMBIGUITY_ENERGY_TOLERANCE || 0.15
);

// Preparation moves energy density more than any other qualifier — frying a
// chicken breast roughly doubles its calories — so a conflict here is
// disqualifying rather than merely penalised.
const LEAN_PREP = new Set([
  'grilled', 'roasted', 'baked', 'boiled', 'steamed', 'poached',
  'broiled', 'barbecued', 'bbq', 'raw', 'fresh', 'skinless',
]);
const FAT_PREP = new Set([
  'fried', 'deepfried', 'breaded', 'battered', 'crispy',
  'sauteed', 'panfried', 'tempura', 'crumbed', 'buttered',
]);

let nutritionDb = null;
let aliasMap = null;
let aliasIndex = null;
let importedAliases = {};
let wordIndex = new Map();
let databaseStats = null;

function prepClass(words) {
  for (const w of words) {
    if (FAT_PREP.has(w)) return 'fat';
  }
  for (const w of words) {
    if (LEAN_PREP.has(w)) return 'lean';
  }
  return null;
}

function load() {
  if (nutritionDb && aliasMap && aliasIndex) return;
  try {
    nutritionDb = JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));
    aliasMap = JSON.parse(fs.readFileSync(ALIASES_PATH, 'utf8'));
    importedAliases = fs.existsSync(USDA_ALIASES_PATH)
      ? JSON.parse(fs.readFileSync(USDA_ALIASES_PATH, 'utf8')) : {};
    console.log(
      `nutrition_db loaded: ${Object.keys(nutritionDb).length} foods, ${Object.keys(aliasMap).length} curated aliases, ${Object.keys(importedAliases).length} USDA aliases`
    );
  } catch (err) {
    console.error('Failed to load nutrition database:', err.message);
    nutritionDb = {};
    aliasMap = {};
  }
  aliasIndex = Object.entries(aliasMap).map(([key, id]) => {
    const words = String(key).split(/\s+/).filter(Boolean);
    return { key, id, words, prep: prepClass(words) };
  });
  for (const [key, ids] of Object.entries(importedAliases)) {
    const words = key.split(/\s+/).filter(Boolean);
    for (const id of ids) aliasIndex.push({ key, id, words, prep: prepClass(words), imported: true });
  }
  wordIndex = new Map();
  for (const candidate of aliasIndex) {
    for (const word of new Set(candidate.words)) {
      if (!wordIndex.has(word)) wordIndex.set(word, []);
      wordIndex.get(word).push(candidate);
    }
  }
  databaseStats = {
    foods: Object.keys(nutritionDb).length,
    usdaFoods: Object.keys(nutritionDb).filter(id => id.startsWith('USDA_')).length,
    usdaAliases: Object.keys(importedAliases).length,
  };
}

function compatible(query, description, curated = false) {
  const qualifiers = text => normalize(text).replace(/\bfat free\b|\bnonfat\b/g, 'skim');
  const normalizedQuery = qualifiers(query);
  const target = qualifiers(description);
  const states = ['raw', 'fried', 'roasted', 'grilled', 'boiled', 'baked', 'steamed',
    'poached', 'broiled', 'dried', 'frozen', 'canned', 'smoked', 'breaded', 'battered'];
  const words = new Set(normalizedQuery.split(' '));
  const targetWords = new Set(target.split(' '));
  for (const qualifier of ['extra virgin', 'extra light', 'low fat', 'reduced fat',
    'fat free', 'whole milk', 'brown rice', 'white rice']) {
    if (normalizedQuery.includes(qualifier) && !target.includes(qualifier)) {
      // USDA often uses comma-separated noun-first descriptions.
      if (!qualifier.split(' ').every(word => targetWords.has(word))) return false;
    }
  }
  for (const state of states) {
    if (words.has(state) && !targetWords.has(state)) {
      const conflicting = states.some(other => targetWords.has(other));
      if (!curated || conflicting || FAT_PREP.has(state)) return false;
    }
  }
  if (words.has('cooked') && targetWords.has('raw')) return false;
  const skin = text => /skinless|without skin|meat only/.test(text) ? 'without'
    : /with skin|skin on|meat and skin/.test(text) ? 'with' : null;
  if (skin(normalize(query)) && skin(normalize(query)) !== skin(target)) return false;
  for (const qualifier of ['skim', 'nonfat', 'unsweetened', 'sweetened', 'drained']) {
    if (words.has(qualifier) && !targetWords.has(qualifier)) return false;
  }
  // Percentage qualifiers distinguish products such as 1% and 2% milk.
  const percentages = text => [...text.matchAll(/\d+(?:\.\d+)?\s*%/g)].map(m => m[0].replace(/\s/g, ''));
  const wanted = percentages(query);
  const actual = percentages(description);
  if (wanted.some(value => !actual.includes(value))) return false;
  return true;
}

// Keeps letters of ANY script. The previous implementation stripped
// [^a-z0-9\s], which deleted Arabic entirely and reduced every Arabic food
// name to an empty string — an unconditional lookup miss.
function normalize(name) {
  return String(name == null ? '' : name)
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

// Scores one alias against the query. Returns 0 for a disqualified candidate.
//
// Replaces the previous rule, which accepted a single shared word whenever
// either side was one word and then took whichever alias happened to come
// first in JSON insertion order. That is how "fried chicken" resolved to
// "Chicken breast, roasted".
function scoreCandidate(queryWords, queryPrep, candidate) {
  const qs = new Set(queryWords);
  const shared = candidate.words.filter((w) => qs.has(w));
  if (shared.length === 0) return 0;

  // Opposite preparations are, energetically, different foods.
  if (queryPrep && candidate.prep && queryPrep !== candidate.prep) return 0;
  // The query names a fat-added preparation the alias does not claim: refuse
  // rather than silently returning the lean version.
  if (queryPrep === 'fat' && candidate.prep !== 'fat') return 0;

  const uniqueShared = new Set(shared).size;
  const coverage = uniqueShared / Math.max(qs.size, candidate.words.length);
  const specificity = uniqueShared / candidate.words.length;
  let score = 0.6 * coverage + 0.4 * specificity;

  // A single word in common is weak evidence on its own.
  if (uniqueShared < 2) score *= 0.5;

  return score;
}

function toResult(id, food) {
  return {
    id,
    displayName: food.display_name,
    per100g: {
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
    },
  };
}

function lookup(foodName) {
  load();
  if (!foodName || typeof foodName !== 'string') return null;
  const normalized = normalize(foodName);
  if (!normalized) return null;

  const exactId = aliasMap[foodName.toLowerCase().trim()] || aliasMap[normalized];
  if (exactId && nutritionDb[exactId] &&
      compatible(foodName, nutritionDb[exactId].display_name, true)) {
    return toResult(exactId, nutritionDb[exactId]);
  }
  const words = normalized.split(/\s+/);
  const prep = prepClass(words);
  const exactImported = importedAliases[normalized] || [];
  if (exactImported.length === 1) {
    const id = exactImported[0];
    const row = nutritionDb[id];
    if (row && normalize(row.display_name) === normalized && compatible(foodName, row.display_name)) {
      return toResult(id, row);
    }
  }
  const candidates = new Set(words.flatMap(word => wordIndex.get(word) || []));
  const bestByFood = new Map();
  for (const candidate of candidates) {
    const food = nutritionDb[candidate.id];
    if (!food || !compatible(foodName, food.usda_description || food.display_name)) continue;
    if (candidate.imported && !sameFoodWords(words, food.display_name)) continue;
    const score = candidate.key === normalized ? 1 : scoreCandidate(words, prep, candidate);
    if (score < MIN_SCORE) continue;
    // Only identical full identities can share a winner; similar calories are not equivalence.
    const identity = food.fdc_id ? 'USDA_' + food.fdc_id : candidate.id;
    const previous = bestByFood.get(identity);
    if (!previous || score > previous.score ||
        (score === previous.score && food.dataset === 'Foundation' &&
         nutritionDb[previous.id].dataset !== 'Foundation')) {
      bestByFood.set(identity, { ...candidate, score });
    }
  }
  const ranked = selectPreferredSources([...bestByFood.values()], nutritionDb)
    .sort((a, b) => b.score - a.score || a.id.localeCompare(b.id));
  if (!ranked.length) return null;
  const [best, next] = ranked;
  if (next && best.score - next.score < AMBIGUITY_MARGIN) {
    if (best.imported || next.imported) return null;
    const a = nutritionDb[best.id].calories;
    const b = nutritionDb[next.id].calories;
    if (Math.max(a, b) && Math.abs(a - b) / Math.max(a, b) > AMBIGUITY_ENERGY_TOLERANCE) return null;
  }
  return toResult(best.id, nutritionDb[best.id]);
}

function getFoodById(id) {
  load();
  const food = nutritionDb[id];
  if (!food) return null;
  return toResult(id, food);
}

function selectPreferredSources(candidates, db) {
  return candidates.filter(candidate => {
    const row = db[candidate.id];
    if (row.dataset !== 'SR Legacy') return true;
    const description = normalize(row.usda_description || row.display_name);
    return !candidates.some(other => db[other.id].dataset === 'Foundation' &&
      other.score >= candidate.score && normalize(db[other.id].display_name) === description);
  });
}

const QUERY_MODIFIERS = new Set(['raw', 'cooked', 'fried', 'roasted', 'grilled', 'boiled',
  'baked', 'steamed', 'poached', 'broiled', 'dried', 'frozen', 'canned', 'smoked',
  'skinless', 'skin', 'with', 'without', 'and', 'only', 'meat', 'on', 'fat', 'free',
  'low', 'reduced', 'whole', 'skim', 'nonfat', 'unsweetened', 'sweetened', 'drained']);
function sameFoodWords(words, description) {
  const singular = word => word.length > 3 && word.endsWith('s') ? word.slice(0, -1) : word;
  const actual = new Set(normalize(description).split(' ').map(singular));
  const required = words.filter(word => !QUERY_MODIFIERS.has(word) && !/^\d+$/.test(word));
  return required.length > 0 && required.every(word => actual.has(singular(word)));
}

function getAllCategories() {
  load();
  const categories = new Set();
  for (const id of Object.keys(nutritionDb)) {
    if (nutritionDb[id].category) categories.add(nutritionDb[id].category);
  }
  return [...categories].sort();
}

function getDatabaseStats() { load(); return { ...databaseStats }; }

module.exports = { lookup, getFoodById, getAllCategories, load, normalize, compatible, selectPreferredSources, getDatabaseStats };
