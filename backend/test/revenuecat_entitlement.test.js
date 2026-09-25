const assert = require('node:assert');
const test = require('node:test');

process.env.NODE_ENV = 'test';
process.env.REQUIRE_APP_CHECK = 'false';

const {
  isProRevenueCatProductId,
  parseRevenueCatSubscriber,
} = require('../server');

test('RevenueCat parser treats active Wazn Pro product as active without entitlement', () => {
  const now = Date.parse('2026-09-13T12:00:00.000Z');
  const result = parseRevenueCatSubscriber({
    entitlements: {},
    subscriptions: {
      'snapcal_pro_annual:annual-plan': {
        expires_date: '2026-10-13T12:00:00.000Z',
      },
    },
  }, now);

  assert.equal(result.isActive, true);
  assert.equal(result.entitlementId, 'pro');
  assert.equal(result.productId, 'snapcal_pro_annual:annual-plan');
});

test('RevenueCat parser does not grant expired or unknown products', () => {
  const now = Date.parse('2026-09-13T12:00:00.000Z');

  assert.equal(isProRevenueCatProductId('snapcal_pro_monthly'), true);
  assert.equal(isProRevenueCatProductId('other_app_product'), false);

  const expired = parseRevenueCatSubscriber({
    entitlements: {},
    subscriptions: {
      snapcal_pro_monthly: {
        expires_date: '2026-08-13T12:00:00.000Z',
      },
    },
  }, now);
  assert.equal(expired.isActive, false);

  const unknown = parseRevenueCatSubscriber({
    entitlements: {},
    subscriptions: {
      other_app_product: {
        expires_date: '2026-10-13T12:00:00.000Z',
      },
    },
  }, now);
  assert.equal(unknown.isActive, false);
  assert.equal(unknown.productId, null);
});

test('webhook events about other products or entitlements do not touch Pro', () => {
  const { webhookEventConcernsPro } = require('../server');

  // A Pro purchase, by entitlement or by product.
  assert.equal(webhookEventConcernsPro({ entitlement_ids: ['pro'], product_id: 'snapcal_pro_monthly' }), true);
  assert.equal(webhookEventConcernsPro({ entitlement_id: 'pro' }), true);
  assert.equal(webhookEventConcernsPro({ product_id: 'snapcal_pro_annual:annual-plan' }), true);

  // Some other product: must neither grant nor revoke Pro.
  assert.equal(webhookEventConcernsPro({ entitlement_ids: ['coach_pack'], product_id: 'coach_pack_1' }), false);
  assert.equal(webhookEventConcernsPro({ product_id: 'other_app_product' }), false);

  // An event naming nothing is read as Pro, as every event was before.
  assert.equal(webhookEventConcernsPro({ type: 'EXPIRATION' }), true);
  assert.equal(webhookEventConcernsPro({ entitlement_ids: [] }), true);
});
