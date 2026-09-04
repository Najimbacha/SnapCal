const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', '..', 'data', 'nutrition_db.json');
const ALIASES_PATH = path.join(__dirname, '..', '..', 'data', 'food_aliases.json');

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
    console.log(
      `nutrition_db loaded: ${Object.keys(nutritionDb).length} foods, ${Object.keys(aliasMap).length} aliases`
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

  // 1. Exact alias — the curated answer always wins.
  const exactId = aliasMap[normalized];
  if (exactId && nutritionDb[exactId]) {
    return toResult(exactId, nutritionDb[exactId]);
  }

  // 2. Best-scoring candidate across the whole index, not the first hit.
  const queryWords = normalized.split(/\s+/).filter(Boolean);
  const queryPrep = prepClass(queryWords);

  let best = null;
  let bestScore = 0;
  // The best score belonging to a *different* food. Two aliases for the same
  // row tying is not ambiguity -- it is the row being well aliased.
  let runnerUp = null;
  let runnerUpScore = 0;
  for (const candidate of aliasIndex) {
    if (!nutritionDb[candidate.id]) continue;
    const score = scoreCandidate(queryWords, queryPrep, candidate);
    if (score > bestScore) {
      if (best && best.id !== candidate.id) {
        runnerUp = best;
        runnerUpScore = bestScore;
      }
      bestScore = score;
      best = candidate;
    } else if (best && candidate.id !== best.id && score > runnerUpScore) {
      runnerUp = candidate;
      runnerUpScore = score;
    }
  }

  if (!best || bestScore < MIN_SCORE) return null;

  if (runnerUp && bestScore - runnerUpScore < AMBIGUITY_MARGIN) {
    const a = Number(nutritionDb[best.id]?.calories) || 0;
    const b = Number(nutritionDb[runnerUp.id]?.calories) || 0;
    const spread = Math.max(a, b) === 0 ? 0 : Math.abs(a - b) / Math.max(a, b);
    // Close on score AND far apart on energy: a coin toss the user would
    // notice. Refuse, and let the estimate downstream answer instead -- it is
    // roughly right, where a confident wrong row is precisely wrong.
    if (spread > AMBIGUITY_ENERGY_TOLERANCE) return null;
  }

  return toResult(best.id, nutritionDb[best.id]);
}

function getFoodById(id) {
  load();
  const food = nutritionDb[id];
  if (!food) return null;
  return toResult(id, food);
}

function getAllCategories() {
  load();
  const categories = new Set();
  for (const id of Object.keys(nutritionDb)) {
    if (nutritionDb[id].category) categories.add(nutritionDb[id].category);
  }
  return [...categories].sort();
}

module.exports = { lookup, getFoodById, getAllCategories, load, normalize };
