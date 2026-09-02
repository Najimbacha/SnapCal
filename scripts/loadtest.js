// k6 load test for the SnapCal API.
//
//   k6 run -e BASE_URL=https://staging... -e TOKENS=./tokens.txt scripts/loadtest.js
//
// Run it against a STAGING project, never production, and seed TOKENS with a
// file of one Firebase ID token per line — at least a few hundred. One token
// measures your cache, not your capacity: every request lands on the same
// entitlement key and the same user document, so the numbers come back
// beautiful and mean nothing.
//
// The two scenarios are separate on purpose. Light traffic (premium-status,
// settings) and scans have completely different shapes: one is thousands of
// short requests, the other is a few dozen sockets held open for tens of
// seconds. Averaging them together hides the thing you are testing for --
// whether a slow scan starves everything else.
//
// You do not test "1 million users". You test the per-user request pattern at
// peak requests-per-second and multiply. The stages below are modelled from
// the audit: ~130 RPS at 250k daily actives, ~650 at peak, 2000 in a spike.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';
import { SharedArray } from 'k6/data';

const BASE_URL = __ENV.BASE_URL;
if (!BASE_URL) throw new Error('Set -e BASE_URL=https://your-staging-host');

const tokens = new SharedArray('tokens', function () {
  const path = __ENV.TOKENS || './tokens.txt';
  return open(path).split('\n').map((t) => t.trim()).filter(Boolean);
});

const premiumLatency = new Trend('premium_status_ms');
const scanLatency = new Trend('scan_ms');
const shedRate = new Rate('scans_shed_503');

export const options = {
  scenarios: {
    light: {
      executor: 'ramping-arrival-rate',
      exec: 'lightTraffic',
      startRate: 10,
      timeUnit: '1s',
      stages: [
        { target: 50, duration: '2m' },    // ~1k concurrent users
        { target: 200, duration: '5m' },   // ~10k
        { target: 650, duration: '5m' },   // ~100k
        { target: 2000, duration: '3m' },  // viral spike
        { target: 50, duration: '2m' },    // recovery: does p95 come back?
      ],
      preAllocatedVUs: 500,
      maxVUs: 3000,
    },
    scans: {
      executor: 'constant-arrival-rate',
      exec: 'scanTraffic',
      rate: 5,
      timeUnit: '1s',
      duration: '17m',
      preAllocatedVUs: 300,
      maxVUs: 600,
    },
  },
  thresholds: {
    // Light endpoints must stay fast even while scans are in flight. This is
    // the single most important assertion in the file.
    'http_req_duration{scenario:light}': ['p(95)<400'],
    'http_req_failed{scenario:light}': ['rate<0.01'],
    // Scans are bounded by an upstream model, so latency is not the assertion.
    // What matters is that they either succeed or are cleanly shed.
    'scans_shed_503': ['rate<0.10'],
  },
};

function authHeaders() {
  const token = tokens[Math.floor(Math.random() * tokens.length)];
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      // App Check is enforced; supply a debug token from the staging project
      // or the requests all fail at the door and you measure nothing.
      'X-Firebase-AppCheck': __ENV.APPCHECK_TOKEN || '',
    },
  };
}

export function lightTraffic() {
  const res = http.get(`${BASE_URL}/api/premium-status`, authHeaders());
  premiumLatency.add(res.timings.duration);
  check(res, { 'premium-status 200': (r) => r.status === 200 });
  sleep(1);
}

// A 1x1 JPEG. Real scans average ~73 KB after client-side compression; swap in
// a realistic image if you are measuring upload bandwidth rather than the
// server's concurrency behaviour.
const TINY_JPEG =
  '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a' +
  'HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAARCAABAAEDASIAAhEBAxEB/8QAHwAA' +
  'AQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIh' +
  'MUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpT' +
  'VFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5' +
  'usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iii' +
  'gD//2Q==';

export function scanTraffic() {
  const res = http.post(
    `${BASE_URL}/v1/scan`,
    JSON.stringify({ image: TINY_JPEG, language: 'en' }),
    Object.assign({ timeout: '70s' }, authHeaders()),
  );
  scanLatency.add(res.timings.duration);
  shedRate.add(res.status === 503);
  check(res, {
    'scan answered or was cleanly shed': (r) => r.status === 200 || r.status === 503 || r.status === 402,
  });
}

export function handleSummary(data) {
  // Three numbers decide whether this passed, in this order.
  const p95 = data.metrics.premium_status_ms
    ? data.metrics.premium_status_ms.values['p(95)']
    : 0;
  const shed = data.metrics.scans_shed_503 ? data.metrics.scans_shed_503.values.rate : 0;
  return {
    stdout:
      '\n' +
      `  premium-status p95 : ${Math.round(p95)} ms  (target < 400)\n` +
      `  scans shed (503)   : ${(shed * 100).toFixed(1)}%  (target < 10%)\n` +
      `  scan p95           : ${Math.round(
        data.metrics.scan_ms ? data.metrics.scan_ms.values['p(95)'] : 0,
      )} ms  (bounded by the AI provider, not by us)\n\n` +
      '  Then check, in the Grafana dashboard: instance count and cold starts,\n' +
      '  snapcal_outbound_sockets_active (should plateau, not climb), and\n' +
      '  Firestore read volume in the console.\n',
  };
}
