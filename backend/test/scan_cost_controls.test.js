const test = require('node:test');
const assert = require('node:assert/strict');

process.env.NODE_ENV = 'test';

const {
  resolveScanPipeline,
  scanResultCacheKey,
  isCachedScanResult,
} = require('../server');

test('production cannot select the expensive legacy pipeline by query string', () => {
  assert.equal(resolveScanPipeline('v2', 'v1', true), 'v2');
  assert.equal(resolveScanPipeline('v1', 'v2', true), 'v1');
});

test('development can explicitly compare scan pipelines', () => {
  assert.equal(resolveScanPipeline('v2', 'v1', false), 'v1');
  assert.equal(resolveScanPipeline('v1', 'v2', false), 'v2');
});

test('scan cache keys isolate users, languages, pipelines and images', () => {
  const base = scanResultCacheKey('user-a', Buffer.from('photo-a'), 'en', 'v2');
  assert.equal(base, scanResultCacheKey('user-a', Buffer.from('photo-a'), 'en', 'v2'));
  assert.notEqual(base, scanResultCacheKey('user-b', Buffer.from('photo-a'), 'en', 'v2'));
  assert.notEqual(base, scanResultCacheKey('user-a', Buffer.from('photo-a'), 'ar', 'v2'));
  assert.notEqual(base, scanResultCacheKey('user-a', Buffer.from('photo-a'), 'en', 'v1'));
  assert.notEqual(base, scanResultCacheKey('user-a', Buffer.from('photo-b'), 'en', 'v2'));
  assert.ok(!base.includes('user-a'));
});

test('only complete scan-shaped values are accepted from cache', () => {
  assert.equal(isCachedScanResult({ items: [], totals: {} }), true);
  assert.equal(isCachedScanResult({ items: [] }), false);
  assert.equal(isCachedScanResult({ totals: {} }), false);
  assert.equal(isCachedScanResult(null), false);
});
