const PROVIDER = (process.env.NUTRITION_PROVIDER || 'local').toLowerCase();

const providers = {
  local: null,
};

function getProvider() {
  if (!providers.local) {
    providers.local = require('./providers/local_json_provider');
  }
  return providers.local;
}

function lookup(foodName) {
  return getProvider().lookup(foodName);
}

function getFoodById(id) {
  return getProvider().getFoodById(id);
}

function getAllCategories() {
  return getProvider().getAllCategories();
}

const PROVIDER_NAMES = {
  local: 'Local JSON Database',
};

function getProviderName() {
  return PROVIDER_NAMES[PROVIDER] || `Custom (${PROVIDER})`;
}

module.exports = { lookup, getFoodById, getAllCategories, getProviderName };
