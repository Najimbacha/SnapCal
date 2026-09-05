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
 *   4. Same without --dry-run, adding --report <audit.json>.
 *
 * Repeat --file for both datasets. Curated aliases stay separate; existing
 * nutrition changes only through the reviewed usda_curated_mappings.json file.
 */

const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', 'data');
const DB_PATH = path.join(DATA_DIR, 'nutrition_db.json');
const ALIASES_PATH = path.join(DATA_DIR, 'usda_aliases.json');

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
      if (PREP_WORDS.has(word)) {
        if (!prep.includes(word)) prep.push(word);
      } else if (NOISE_WORDS.has(word) || word.length < 3) {
        continue;
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
  const list = Array.isArray(food?.foodNutrients) ? food.foodNutrients : [];
  for (const entry of list) {
    const nid = entry?.nutrient?.id ?? entry?.nutrientId;
    if (nid === id) {
      const raw = entry.amount ?? entry.value;
      if (raw === null || raw === undefined || raw === '') continue;
      if (typeof raw !== 'number' && typeof raw !== 'string') continue;
      if (typeof raw === 'string' && !raw.trim()) continue;
      const unit = entry.nutrient?.unitName;
      if (unit && unit.toLowerCase() !== (id === 1003 || id === 1004 || id === 1005 ? 'g' : 'kcal')) continue;
      const amount = Number(raw);
      if (Number.isFinite(amount)) return amount;
    }
  }
  return null;
}

/// USDA values are already per 100g for these datasets. Anything outside the
/// physically possible is a parsing mistake, not a food.
function toRow(food) {
  // A null hole in the array is not a food. USDA ships them: the Foundation
  // Foods export has entries that are literally null, and without this the
  // whole import dies on one of them partway through.
  if (!food || typeof food !== 'object') return null;

  const energyId = [2048, 1008, 2047].find(id => nutrientAmount(food, id) !== null);
  const calories = energyId === undefined ? null : nutrientAmount(food, energyId);
  if (calories === null || calories < 0 || calories > 900) return null;

  const protein = nutrientAmount(food, NUTRIENT.PROTEIN);
  const carbs = nutrientAmount(food, NUTRIENT.CARBS);
  const fat = nutrientAmount(food, NUTRIENT.FAT);
  if ([protein, carbs, fat].some(v => v === null)) return null;
  if ([protein, carbs, fat].some((v) => v < 0 || v > 100)) return null;

  const description = String(food.description || '').trim();
  if (!description || !Number.isSafeInteger(food.fdcId) || food.fdcId <= 0) return null;

  return {
    row: {
      display_name: description,
      calories,
      protein,
      carbs,
      fat,
      category: String(food.foodCategory?.description || 'usda').toLowerCase().slice(0, 40),
      source: 'usda',
      fdc_id: food.fdcId,
      dataset: food.dataType || 'SR Legacy',
      energy_nutrient_id: energyId,
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

function buildImport(existing, foods, mappings = []) {
  const db = { ...existing };
  const aliases = Object.create(null);
  const report = { read: foods.length, skipped: [], duplicateIds: [], collisions: [], updatedExisting: [] };
  const seen = new Map();
  const addAlias = (key, id) => {
    if (!key) return;
    const ids = aliases[key] ||= [];
    if (!ids.includes(id)) ids.push(id);
  };
  for (const food of foods) {
    if (food && !['SR Legacy', 'Foundation'].includes(food.dataType)) {
      throw new Error('Unsupported dataset: ' + food.dataType);
    }
    const parsed = toRow(food);
    if (!parsed) {
      report.skipped.push({ fdc_id: food?.fdcId ?? null, description: food?.description ?? null,
        reason: 'Missing, invalid or incomplete per-100g nutrition or identity' });
      continue;
    }
    const id = 'USDA_' + food.fdcId;
    if (seen.has(id)) {
      if (JSON.stringify(seen.get(id)) !== JSON.stringify(parsed.row)) {
        throw new Error('Conflicting records for ' + id);
      }
      report.duplicateIds.push(id);
      continue;
    }
    seen.set(id, parsed.row);
    db[id] = parsed.row;
  }
  // Regenerate the index from all imported rows so repeated imports are stable.
  for (const id of Object.keys(db).sort()) {
    if (!id.startsWith('USDA_')) continue;
    const row = db[id];
    addAlias(normalize(row.display_name), id);
    addAlias(shortAlias(row.display_name), id);
  }
  for (const [name, ids] of Object.entries(aliases)) {
    ids.sort();
    if (ids.length > 1) report.collisions.push({ name, ids });
  }
  for (const mapping of mappings) {
    const current = db[mapping.id];
    const source = db['USDA_' + mapping.fdc_id];
    if (!current || current.display_name !== mapping.expected_name ||
        !source || source.display_name !== mapping.usda_description) {
      throw new Error('Reviewed mapping no longer matches: ' + mapping.id);
    }
    const updated = { ...current, ...source, display_name: current.display_name,
      category: current.category, usda_description: source.display_name };
    if (JSON.stringify(current) !== JSON.stringify(updated)) {
      report.updatedExisting.push({ id: mapping.id, reason: mapping.reason, before: current, after: updated });
    }
    db[mapping.id] = updated;
  }
  report.foodsBefore = Object.keys(existing).length;
  report.foodsAfter = Object.keys(db).length;
  report.importedRecords = Object.keys(db).filter(id => id.startsWith('USDA_')).length;
  report.aliasCount = Object.keys(aliases).length;
  return { db, aliases, report };
}

function main() {
  const files = process.argv.flatMap((value, i, args) => value === '--file' ? [args[i + 1]] : []);
  if (!files.length || files.some(file => !file || !fs.existsSync(file))) {
    throw new Error('Supply --file <SR Legacy.json> --file <Foundation.json> [--dry-run] [--report <path>]');
  }
  const existing = JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));
  const mappings = JSON.parse(fs.readFileSync(path.join(DATA_DIR, 'usda_curated_mappings.json'), 'utf8'));
  const result = buildImport(existing, files.flatMap(readFoods), mappings);
  const summary = { ...result.report, skipped: result.report.skipped.length,
    collisions: result.report.collisions.length, duplicateIds: result.report.duplicateIds.length };
  console.log(JSON.stringify(summary, null, 2));
  if (DRY_RUN) {
    console.log('Dry run. Nothing written.');
    return;
  }
  const reportPath = arg('report');
  if (!reportPath) throw new Error('An applied import requires --report <path> for the audit record.');
  const write = (file, value) => fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
  // Build and validate everything before replacing either runtime file.
  write(reportPath, { inputs: files.map(file => path.basename(file)), ...result.report });
  write(DB_PATH, result.db);
  write(ALIASES_PATH, result.aliases);
  console.log('Written database, candidate aliases and import report.');
}

module.exports = { shortAlias, toRow, normalize, buildImport, readFoods };
if (require.main === module) main();
