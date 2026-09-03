const test = require('node:test');
const assert = require('node:assert');

// Set before requiring the server so the module-level constants pick them up.
process.env.FREE_MONTHLY_SCANS = '3';
process.env.MAX_BONUS_SCANS_PER_MONTH = '10';

const { bonusScansFor, freeAllowanceFor } = require('../server');

const MONTH = '2026-09';

test('no usage document means no bonus and the base allowance', () => {
  assert.strictEqual(bonusScansFor(undefined, MONTH), 0);
  assert.strictEqual(bonusScansFor({}, MONTH), 0);
  assert.strictEqual(freeAllowanceFor({}, MONTH), 3);
});

test('a bonus earned this month raises the allowance', () => {
  const usage = { monthKey: MONTH, bonusScans: 2 };
  assert.strictEqual(bonusScansFor(usage, MONTH), 2);
  assert.strictEqual(freeAllowanceFor(usage, MONTH), 5);
});

test("last month's bonus does not carry over", () => {
  // This is the case that matters most: the usage document is not cleared at
  // the month boundary, it is stamped with a monthKey. A bonus from August
  // must not quietly extend September's allowance.
  const usage = { monthKey: '2026-08', bonusScans: 7 };
  assert.strictEqual(bonusScansFor(usage, MONTH), 0);
  assert.strictEqual(freeAllowanceFor(usage, MONTH), 3);
});

test('the monthly cap bounds what a forged count is worth', () => {
  // The grant endpoint refuses past the cap, but a value written some other
  // way must not be honoured either -- the read is where enforcement has to
  // hold, not the write.
  const usage = { monthKey: MONTH, bonusScans: 9999 };
  assert.strictEqual(bonusScansFor(usage, MONTH), 10);
  assert.strictEqual(freeAllowanceFor(usage, MONTH), 13);
});

test('junk in the bonus field is treated as zero, not as a crash', () => {
  for (const bad of [null, 'four', NaN, -3, undefined, {}]) {
    const usage = { monthKey: MONTH, bonusScans: bad };
    assert.strictEqual(bonusScansFor(usage, MONTH), 0, `bonusScans: ${String(bad)}`);
  }
});

test('a fractional bonus rounds down rather than granting a partial scan', () => {
  assert.strictEqual(bonusScansFor({ monthKey: MONTH, bonusScans: 2.9 }, MONTH), 2);
});
