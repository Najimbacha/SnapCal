#!/usr/bin/env node
/**
 * Imports USDA FoodData Central into nutrition_db.json.
 *
 * The curated table had 285 foods, and a miss used to mean a meal logged with
 * no nutrition at all. USDA publishes its datasets as free, public-domain
 * downloads, so this is not building a database -- it is adopting one that
 * already exists, once, with no runtime dependency and nothing to maintain.
 *
 *   1. Download a dataset from https://fdc.nal.usda.gov/download-datasets.html
 *      "SR Legacy" and "Foundation Foods" in JSON are the two worth having.
 *   2. Unzip it.
 *   3. node scripts/import-usda.js --file <path-to.json> --dry-run
 *   4. Same without --dry-run once the numbers look sane.
 *
 * Curated rows and curated aliases are never overwritten. They were chosen by
 * hand and they win; USDA only fills gaps.
 */

const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', 'data');
const DB_PATH = path.join(DATA_DIR, 'nutrition_db.json');
const ALIASES_PATH = path.join(DATA_DIR, 'food_aliases.json');

// FoodData Central nutrient ids. These are stable across releases.
const NUTRIENT = { ENERGY_KCAL: 1008, PROTEIN: 1003, CARBS: 1005, FAT: 1004 };

// Descriptions carry the preparation after the food, and it matters more than
// anything else for energy density, so it is kept in the short alias.
const PREP_WORDS = new Set([
  'raw', 'cooked', 'roasted', 'boiled', 'baked', 'grilled', 'broiled',
  'fried', 'steamed', 'braised', 'stewed', 'canned', 'dried', 'frozen',
  'smoked', 'toasted', 'poached', 'sauteed', 'breaded', 'battered',
]);

// Words that describe the sample, not the food. They add length without
// meaning and drag the match score down.
const NOISE_WORDS = new Set([
  'includes', 'usda', 'commodity', 'all', 'types', 'varieties', 'unspecified',
  'commercially', 'prepared', 'home', 'restaurant', 'brand', 'name',
  'formulation', 'reformulated', 'added', 'without', 'with', 'and', 'or',
  'from', 'the', 'of', 'in', 'to', 'not', 'further', 'specified', 'nfs',
  // USDA's livestock and processing vocabulary. These crowd out the word
  // that actually identifies the cut: "Chicken, broilers or fryers, breast"
  // was becoming "chicken broilers" and losing the breast.
  'broilers', 'fryers', 'roasters', 'stewing', 'composite', 'cuts',
  'separable', 'lean', 'only', 'meat', 'trimmed', 'retail', 'select',
  'choice', 'grade', 'regular', 'enriched', 'unenriched', 'fortified',
  'salad', 'cooking', 'value', 'values', 'per', 'each', 'raw',
]);

function arg(name) {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? null : process.argv[i + 1];
}
const DRY_RUN = process.argv.includes('--dry-run');

function normalize(name) {
  return String(name == null ? '' : name)
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/// A short, matchable key from a USDA description.
///
/// "Chicken, broilers or fryers, breast, meat only, cooked, roasted"
///   -> "chicken breast roasted"
///
/// The first comma segment names the food; later segments qualify it. Only the
/// preparation and one distinguishing qualifier are kept, because the matcher
/// scores on how much of the candidate the query covers, and a twelve-word
/// alias can never be covered by "chicken breast".
function shortAlias(description) {
  const segments = String(description).split(',').map((s) => normalize(s)).filter(Boolean);
  if (segments.length === 0) return null;

  const head = segments[0].split(/\s+/).filter((w) => !NOISE_WORDS.has(w));
  const prep = [];
  const qualifiers = [];

  for (const segment of segments.slice(1)) {
    for (const word of segment.split(/\s+/)) {
      if (NOISE_WORDS.has(word) || word.length < 3) continue;
      if (PREP_WORDS.has(word)) {
        if (!prep.includes(word)) prep.push(word);
      } else if (qualifiers.length < 2 && !qualifiers.includes(word)) {
        qualifiers.push(word);
      }
    }
  }

  // The last preparation named is the most specific: "cooked, roasted" is a
  // roast, and "roasted" is what a user or a detector would say.
  const finalPrep = prep.length > 0 ? [prep[prep.length - 1]] : [];
  const words = [...head.slice(0, 2), ...qualifiers.slice(0, 1), ...finalPrep];
  const alias = [...new Set(words)].join(' ').trim();
  return alias.length >= 3 ? alias : null;
}

function nutrientAmount(food, id) {
  const list = Array.isArray(food.foodNutrients) ? food.foodNutrients : [];
  for (const entry of list) {
    const nid = entry?.nutrient?.id ?? entry?.nutrientId;
    if (nid === id) {
      const amount = Number(entry.amount ?? entry.value);
      if (Number.isFinite(amount)) return amount;
    }
  }
  return null;
}

/// USDA values are already per 100g for these datasets. Anything outside the
/// physically possible is a parsing mistake, not a food.
function toRow(food) {
  const calories = nutrientAmount(food, NUTRIENT.ENERGY_KCAL);
  if (calories === null || calories < 0 || calories > 900) return null;

  const protein = nutrientAmount(food, NUTRIENT.PROTEIN) ?? 0;
  const carbs = nutrientAmount(food, NUTRIENT.CARBS) ?? 0;
  const fat = nutrientAmount(food, NUTRIENT.FAT) ?? 0;
  if ([protein, carbs, fat].some((v) => v < 0 || v > 100)) return null;
  if (calories === 0 && protein === 0 && carbs === 0 && fat === 0) return null;

  const description = String(food.description || '').trim();
  if (!description) return null;

  return {
    row: {
      display_name: description.slice(0, 120),
      calories: Math.round(calories),
      protein: Math.round(protein * 10) / 10,
      carbs: Math.round(carbs * 10) / 10,
      fat: Math.round(fat * 10) / 10,
      category: String(food.foodCategory?.description || 'usda').toLowerCase().slice(0, 40),
      source: 'usda',
      fdc_id: food.fdcId,
    },
    alias: shortAlias(description),
    full: normalize(description),
  };
}

function readFoods(filePath) {
  const parsed = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  if (Array.isArray(parsed)) return parsed;
  // The published files wrap the array under a dataset-specific key.
  for (const key of ['SRLegacyFoods', 'FoundationFoods', 'SurveyFoods', 'foods']) {
    if (Array.isArray(parsed[key])) return parsed[key];
  }
  const firstArray = Object.values(parsed).find((v) => Array.isArray(v));
  if (firstArray) return firstArray;
  throw new Error('No food array found in that file.');
}

function main() {
  const file = arg('file');
  if (!file) {
    console.error('Usage: node scripts/import-usda.js --file <usda.json> [--dry-run] [--limit N]');
    process.exit(1);
  }
  if (!fs.existsSync(file)) {
    console.error(`Not found: ${file}`);
    process.exit(1);
  }

  const limit = Number(arg('limit') || 0);
  const db = JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));
  const aliases = JSON.parse(fs.readFileSync(ALIASES_PATH, 'utf8'));

  const curatedIds = new Set(Object.keys(db));
  const curatedAliases = new Set(Object.keys(aliases));

  const foods = readFoods(file);
  console.log(`Read ${foods.length} foods from ${path.basename(file)}`);

  let added = 0;
  let skippedNoData = 0;
  let skippedNoAlias = 0;
  let aliasTaken = 0;

  for (const food of foods) {
    if (limit && added >= limit) break;

    const parsed = toRow(food);
    if (!parsed) { skippedNoData += 1; continue; }
    if (!parsed.alias) { skippedNoAlias += 1; continue; }

    const id = `USDA_${food.fdcId}`;
    if (curatedIds.has(id)) continue;

    // A curated alias is a hand-made decision and always wins. So does the
    // first USDA row to claim a key -- SR Legacy is ordered sensibly enough
    // that the plainer entry tends to come first.
    const free = !curatedAliases.has(parsed.alias) && !aliases[parsed.alias];
    if (!free) {
      aliasTaken += 1;
      // Still worth storing under its full description: a long, specific
      // query can find it even when the short key is spoken for.
      if (!aliases[parsed.full]) {
        db[id] = parsed.row;
        aliases[parsed.full] = id;
        added += 1;
      }
      continue;
    }

    db[id] = parsed.row;
    aliases[parsed.alias] = id;
    if (parsed.full !== parsed.alias && !aliases[parsed.full]) {
      aliases[parsed.full] = id;
    }
    added += 1;
  }

  console.log('');
  console.log(`  added                : ${added}`);
  console.log(`  no usable nutrition  : ${skippedNoData}`);
  console.log(`  no usable alias      : ${skippedNoAlias}`);
  console.log(`  short alias taken    : ${aliasTaken} (stored under full description)`);
  console.log('');
  console.log(`  foods   : ${curatedIds.size} -> ${Object.keys(db).length}`);
  console.log(`  aliases : ${curatedAliases.size} -> ${Object.keys(aliases).length}`);

  if (DRY_RUN) {
    console.log('\nDry run. Nothing written.');
    return;
  }

  fs.writeFileSync(DB_PATH, `${JSON.stringify(db, null, 2)}\n`);
  fs.writeFileSync(ALIASES_PATH, `${JSON.stringify(aliases, null, 2)}\n`);
  console.log('\nWritten. Run the tests before committing.');
}

module.exports = { shortAlias, toRow, normalize };

if (require.main === module) main();
