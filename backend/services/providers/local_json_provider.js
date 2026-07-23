const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', '..', 'data', 'nutrition_db.json');
const ALIASES_PATH = path.join(__dirname, '..', '..', 'data', 'food_aliases.json');

let nutritionDb = null;
let aliasMap = null;

function load() {
  if (nutritionDb && aliasMap) return;
  try {
    nutritionDb = JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));
    aliasMap = JSON.parse(fs.readFileSync(ALIASES_PATH, 'utf8'));
    console.log(`nutrition_db loaded: ${Object.keys(nutritionDb).length} foods, ${Object.keys(aliasMap).length} aliases`);
  } catch (err) {
    console.error('Failed to load nutrition database:', err.message);
    nutritionDb = {};
    aliasMap = {};
  }
}

function normalize(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function lookup(foodName) {
  load();

  if (!foodName || typeof foodName !== 'string') return null;

  const normalized = normalize(foodName);
  if (!normalized) return null;

  const aliasId = aliasMap[normalized];
  if (aliasId && nutritionDb[aliasId]) {
    const food = nutritionDb[aliasId];
    return { id: aliasId, displayName: food.display_name, per100g: { calories: food.calories, protein: food.protein, carbs: food.carbs, fat: food.fat } };
  }

  const normWords = normalized.split(/\s+/).filter(Boolean);
  const subMatch = Object.entries(aliasMap).find(([key]) => {
    if (normalized === key) return true;
    if (key.length < 4 && normWords.includes(key)) return true;
    if (key.length >= 4) {
      const keyWords = key.split(/\s+/).filter(Boolean);
      const shared = normWords.filter(w => keyWords.includes(w));
      if (shared.length >= Math.min(2, Math.min(normWords.length, keyWords.length))) return true;
    }
    return false;
  });
  if (subMatch) {
    const id = subMatch[1];
    const food = nutritionDb[id];
    if (food) {
      return { id, displayName: food.display_name, per100g: { calories: food.calories, protein: food.protein, carbs: food.carbs, fat: food.fat } };
    }
  }

  return null;
}

function getFoodById(id) {
  load();
  const food = nutritionDb[id];
  if (!food) return null;
  return { id, displayName: food.display_name, per100g: { calories: food.calories, protein: food.protein, carbs: food.carbs, fat: food.fat } };
}

function getAllCategories() {
  load();
  const categories = new Set();
  for (const id of Object.keys(nutritionDb)) {
    if (nutritionDb[id].category) categories.add(nutritionDb[id].category);
  }
  return [...categories].sort();
}

module.exports = { lookup, getFoodById, getAllCategories, load };
