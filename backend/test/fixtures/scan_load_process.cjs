// Isolated benchmark fixture. Never shipped in the production image.
Object.assign(process.env, {
  NODE_ENV: 'test', REQUIRE_APP_CHECK: 'false', REQUIRE_SHARED_REDIS: 'false',
  REDIS_URL: '', K_SERVICE: '', FIREBASE_SERVICE_ACCOUNT: '',
  DEEPSEEK_API_KEY: 'mock-only', AI_IMAGE_PROVIDER_ORDER: 'deepseek',
  AI_TEXT_PROVIDER_ORDER: 'deepseek', SCAN_PIPELINE: 'v2', MAX_CONCURRENT_SCANS: '10',
  SCAN_RATE_LIMIT: '1000', REVENUECAT_SECRET_API_KEY: '',
});
const axios = require('axios');
// All external AI HTTP paths are intercepted, including unexpected fallbacks.
axios.get = async () => { throw new Error('Unexpected external HTTP'); };
axios.post = async () => {
  await new Promise(resolve => setTimeout(resolve, 500));
  return { data: { choices: [{ message: { content: JSON.stringify({ foods: [{
    name: 'Rice', match_key: 'rice', estimated_weight_g: 100,
    per_100g: { calories: 130, protein_g: 2.7, carbs_g: 28, fat_g: 0.3 },
  }] }) }, finish_reason: 'stop' }] } };
};
const { app, setAuthVerifierForTest } = require('../../server');
const db = require('firebase-admin').firestore();
const ref = path => ({
  path,
  collection: name => ({ doc: id => ref(`${path}/${name}/${id}`) }),
  get: async () => ({ exists: true, data: () => ({ isActive: true }) }),
  set: async () => {},
});
db.collection = name => ({ doc: id => ref(`${name}/${id}`) });
db.runTransaction = async run => run({
  get: async reference => ({ exists: true, data: () => reference.path.includes('/subscription/') ? { isActive: true } : {} }),
  set: () => {},
});
setAuthVerifierForTest(async () => ({ uid: 'load-test-user' }));
let peak = process.memoryUsage().rss;
const sample = () => { peak = Math.max(peak, process.memoryUsage().rss, process.resourceUsage().maxRSS * 1024); };
const interval = setInterval(sample, 10);
const server = app.listen(0, '127.0.0.1', () => process.send({ port: server.address().port }));
process.on('message', message => {
  if (message === 'result') { sample(); process.send({ peakRssMiB: Math.ceil(peak / 1024 / 1024) }); }
  if (message === 'stop') { clearInterval(interval); server.close(() => process.exit(0)); }
});
