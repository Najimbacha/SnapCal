const axios = require('axios');

const SEARCH_URL = 'https://api.nal.usda.gov/fdc/v1/foods/search';
const CACHE_TTL_MS = 6 * 60 * 60 * 1000;
const CACHE_MAX = 500;
const cache = new Map();

const NUTRIENT_IDS = { calories: 1008, protein: 1003, fat: 1004, carbs: 1005 };
const KJ_ID = 1062;

function stripZeros(code) {
  return String(code).replace(/^0+/, '');
}

function titleCase(text) {
  const clean = String(text || '').trim();
  if (!clean) return '';
  if (clean !== clean.toUpperCase()) return clean;
  return clean.toLowerCase().replace(/(^|[\s(/-])([a-z])/g, (m, a, b) => a + b.toUpperCase());
}

function number(value) {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

// Turns one USDA "Branded" food into the small shape the app needs. USDA's
// labelled nutrients are per 100 g (or per 100 ml for drinks).
function normalizeBrandedFood(food) {
  const byId = new Map();
  for (const n of Array.isArray(food.foodNutrients) ? food.foodNutrients : []) {
    const id = n.nutrientId ?? n.nutrient?.id;
    const value = number(n.value ?? n.amount);
    if (id != null && value != null && !byId.has(id)) byId.set(id, value);
  }

  let calories = byId.get(NUTRIENT_IDS.calories);
  if (calories == null && byId.has(KJ_ID)) calories = byId.get(KJ_ID) / 4.184;
  const per100g = {
    calories: calories ?? null,
    protein: byId.get(NUTRIENT_IDS.protein) ?? null,
    carbs: byId.get(NUTRIENT_IDS.carbs) ?? null,
    fat: byId.get(NUTRIENT_IDS.fat) ?? null,
  };
  if (Object.values(per100g).every((v) => v == null)) return null;

  const unit = String(food.servingSizeUnit || '').toLowerCase();
  const servingSize = number(food.servingSize);
  const weighable = ['g', 'grm', 'ml', 'mlt'].includes(unit);
  const name = titleCase(food.description);
  if (!name) return null;

  return {
    name,
    brand: titleCase(food.brandName || food.brandOwner),
    servingSize: weighable && servingSize > 0 ? servingSize : null,
    servingText: String(food.householdServingFullText || '').trim().slice(0, 80),
    per100g,
  };
}

function remember(key, value) {
  if (cache.size >= CACHE_MAX) cache.delete(cache.keys().next().value);
  cache.set(key, { value, at: Date.now() });
}

// Looks a barcode up in USDA FoodData Central's branded foods. Returns the
// product, or null when there is no exact barcode match. Throws when USDA
// cannot be reached, so the caller can tell "not found" from "unavailable".
async function lookupBarcode(code, { apiKey, http = axios } = {}) {
  const wanted = stripZeros(code);
  const hit = cache.get(wanted);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.value;

  const response = await http.get(SEARCH_URL, {
    params: { query: code, dataType: 'Branded', pageSize: 10, api_key: apiKey },
    timeout: 8000,
  });
  const foods = Array.isArray(response.data?.foods) ? response.data.foods : [];
  const match = foods.find((f) => stripZeros(f.gtinUpc || '') === wanted);
  const product = match ? normalizeBrandedFood(match) : null;
  remember(wanted, product);
  return product;
}

function clearCache() {
  cache.clear();
}

module.exports = { lookupBarcode, normalizeBrandedFood, titleCase, clearCache };
