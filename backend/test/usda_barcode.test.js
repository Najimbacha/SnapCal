const assert = require('node:assert');
const http = require('node:http');
const test = require('node:test');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';
delete process.env.USDA_API_KEY;

const {
  lookupBarcode,
  normalizeBrandedFood,
  titleCase,
  clearCache,
} = require('../services/usda_barcode');
const { app, setAuthVerifierForTest } = require('../server');

const oatBar = {
  description: 'OAT BAR',
  brandOwner: 'ACME FOODS',
  gtinUpc: '012345678905',
  servingSize: 40,
  servingSizeUnit: 'g',
  householdServingFullText: '1 bar',
  foodNutrients: [
    { nutrientId: 1008, unitName: 'KCAL', value: 400 },
    { nutrientId: 1003, unitName: 'G', value: 10 },
    { nutrientId: 1005, unitName: 'G', value: 60 },
    { nutrientId: 1004, unitName: 'G', value: 12 },
  ],
};

function fakeHttp(foods, calls = []) {
  return {
    get: async (url, options) => {
      calls.push({ url, options });
      return { data: { foods } };
    },
  };
}

test('a branded food becomes per-100 g nutrition with its serving', () => {
  const product = normalizeBrandedFood(oatBar);
  assert.equal(product.name, 'Oat Bar');
  assert.equal(product.brand, 'Acme Foods');
  assert.equal(product.servingSize, 40);
  assert.equal(product.servingText, '1 bar');
  assert.deepEqual(product.per100g, { calories: 400, protein: 10, carbs: 60, fat: 12 });
});

test('energy given only in kJ is converted to kcal', () => {
  const product = normalizeBrandedFood({
    ...oatBar,
    foodNutrients: [{ nutrientId: 1062, value: 1673.6 }],
  });
  assert.equal(Math.round(product.per100g.calories), 400);
});

test('a food with no nutrition or name is not a product', () => {
  assert.equal(normalizeBrandedFood({ ...oatBar, foodNutrients: [] }), null);
  assert.equal(normalizeBrandedFood({ ...oatBar, description: '' }), null);
});

test('mixed-case names are left alone, capitals are tidied', () => {
  assert.equal(titleCase('Greek yogurt'), 'Greek yogurt');
  assert.equal(titleCase('GREEK YOGURT (LOW-FAT)'), 'Greek Yogurt (Low-Fat)');
});

test('only an exact barcode match counts, and 12 vs 13 digits are the same code', async () => {
  clearCache();
  const other = { ...oatBar, gtinUpc: '999999999999' };
  const found = await lookupBarcode('0012345678905', {
    apiKey: 'k',
    http: fakeHttp([other, oatBar]),
  });
  assert.equal(found.name, 'Oat Bar');

  clearCache();
  const none = await lookupBarcode('0012345678905', {
    apiKey: 'k',
    http: fakeHttp([other]),
  });
  assert.equal(none, null);
});

test('the same barcode is not looked up twice', async () => {
  clearCache();
  const calls = [];
  const client = fakeHttp([oatBar], calls);
  await lookupBarcode('012345678905', { apiKey: 'k', http: client });
  await lookupBarcode('012345678905', { apiKey: 'k', http: client });
  assert.equal(calls.length, 1);
  assert.equal(calls[0].options.params.api_key, 'k');
});

test('an unreachable database is an error, not "not found"', async () => {
  clearCache();
  await assert.rejects(
    lookupBarcode('012345678905', {
      apiKey: 'k',
      http: { get: async () => { throw new Error('boom'); } },
    }),
    /boom/,
  );
});

function get(server, path, headers = {}) {
  return new Promise((resolve, reject) => {
    http
      .get(server.url + path, { headers }, (res) => {
        let data = '';
        res.on('data', (c) => { data += c; });
        res.on('end', () => resolve({ status: res.statusCode, body: data ? JSON.parse(data) : null }));
      })
      .on('error', reject);
  });
}

test('the barcode route needs sign-in, a valid code, and a configured key', async () => {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  server.url = `http://127.0.0.1:${server.address().port}`;
  setAuthVerifierForTest(async () => ({ uid: 'user12345', admin: false }));
  try {
    assert.equal((await get(server, '/api/barcode/5449000000996')).status, 401);

    const auth = { Authorization: 'Bearer valid' };
    assert.equal((await get(server, '/api/barcode/not-a-code', auth)).status, 400);
    assert.equal((await get(server, '/api/barcode/123', auth)).status, 400);
    // No USDA key in the test environment.
    assert.equal((await get(server, '/api/barcode/5449000000996', auth)).status, 503);
  } finally {
    setAuthVerifierForTest(null);
    await new Promise((resolve) => server.close(resolve));
  }
});
