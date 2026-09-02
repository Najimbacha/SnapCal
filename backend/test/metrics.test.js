const test = require('node:test');
const assert = require('node:assert');

const { Counter, Histogram, Gauge, renderMetrics, metrics } = require('../metrics');

test('counter renders one series per label set', () => {
  const c = new Counter('t_total', 'help', ['a']);
  c.inc({ a: 'x' });
  c.inc({ a: 'x' });
  c.inc({ a: 'y' }, 5);
  const out = c.render();
  assert.match(out, /^t_total\{a="x"\} 2$/m);
  assert.match(out, /^t_total\{a="y"\} 5$/m);
  assert.match(out, /# TYPE t_total counter/);
});

test('a counter with no observations renders nothing', () => {
  // An empty series is not the same as a zero, and emitting a bare HELP/TYPE
  // pair with no samples makes some scrapers warn.
  assert.strictEqual(new Counter('empty_total', 'help').render(), '');
});

test('histogram buckets are cumulative and agree with the count', () => {
  const h = new Histogram('lat_seconds', 'help', [], [1, 2.5, 5, 10]);
  [0.4, 1.2, 7.5, 99].forEach((v) => h.observe({}, v));
  const out = h.render();

  // Parse the exposition text rather than pattern-matching it: escaping `+Inf`
  // into a regex is exactly the kind of test-only cleverness that fails for
  // reasons unrelated to the code under test.
  const buckets = new Map();
  for (const line of out.split('\n')) {
    const m = line.match(/^lat_seconds_bucket\{le="([^"]+)"\} (\d+)$/);
    if (m) buckets.set(m[1], Number(m[2]));
  }
  const bucket = (le) => {
    assert.ok(buckets.has(le), `no bucket for le=${le} in:\n${out}`);
    return buckets.get(le);
  };

  // The regression this guards: observe() and render() both cumulating meant
  // buckets exceeded _count and every quantile drawn from them was wrong.
  assert.strictEqual(bucket('1'), 1);
  assert.strictEqual(bucket('2.5'), 2);
  assert.strictEqual(bucket('5'), 2);
  assert.strictEqual(bucket('10'), 3);
  assert.strictEqual(bucket('+Inf'), 4);

  assert.match(out, /lat_seconds_count\{?\}? 4/);

  // Monotonicity is the invariant a Prometheus histogram must satisfy.
  const les = [1, 2.5, 5, 10].map((le) => bucket(String(le)));
  for (let i = 1; i < les.length; i++) {
    assert.ok(les[i] >= les[i - 1], 'buckets must not decrease');
  }
});

test('label values with quotes cannot break the exposition format', () => {
  const c = new Counter('esc_total', 'help', ['detail']);
  c.inc({ detail: 'he said "hi"\nand left' });
  const out = c.render();
  assert.match(out, /esc_total\{detail="he said \\"hi\\"\\nand left"\} 1/);
});

test('gauges are evaluated at render time, not at registration', () => {
  let value = 1;
  const g = new Gauge('g_now', 'help', () => value);
  assert.match(g.render(), /g_now 1/);
  value = 42;
  assert.match(g.render(), /g_now 42/);
});

test('the registry renders a parseable document', () => {
  metrics.scans.inc({ outcome: 'success', provider: 'groq' });
  const out = renderMetrics();
  assert.ok(out.endsWith('\n'), 'must end with a newline');
  for (const line of out.split('\n')) {
    if (line === '' || line.startsWith('#')) continue;
    assert.match(line, /^[a-zA-Z_][a-zA-Z0-9_]*(\{.*\})? -?[\d.e+-]+$/, `bad sample line: ${line}`);
  }
});
