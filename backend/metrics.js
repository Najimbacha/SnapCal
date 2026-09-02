/**
 * Prometheus metrics for the SnapCal API.
 *
 * Why this is not `prom-client`
 * -----------------------------
 * The exposition format is a few lines of text and the only types we need are
 * counters, gauges and histograms. A dependency-free module keeps the
 * container small and means metrics can never be the reason a deploy fails to
 * install. If you later want the default Node collectors (GC pauses, event
 * loop lag), swapping in prom-client is a contained change: keep the helper
 * names below and re-implement them over its registry.
 *
 * What this replaces
 * ------------------
 * `/health` counted scan outcomes in a per-process array. With more than one
 * instance that array describes one arbitrary instance, so the failure rate it
 * reported was a sample of unknown size from an unknown fraction of traffic.
 * These metrics are scraped per instance and aggregated by the backend, which
 * is the only way the numbers mean anything once you autoscale.
 */

const DEFAULT_BUCKETS = [0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60];

function serializeLabels(labels) {
  const keys = Object.keys(labels).sort();
  if (keys.length === 0) return '';
  const body = keys
    .map((k) => `${k}="${String(labels[k]).replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n')}"`)
    .join(',');
  return `{${body}}`;
}

class Counter {
  constructor(name, help, labelNames = []) {
    this.name = name;
    this.help = help;
    this.labelNames = labelNames;
    this.values = new Map();
  }

  inc(labels = {}, value = 1) {
    const key = serializeLabels(labels);
    this.values.set(key, (this.values.get(key) || 0) + value);
  }

  render() {
    const lines = [`# HELP ${this.name} ${this.help}`, `# TYPE ${this.name} counter`];
    if (this.values.size === 0) return '';
    for (const [labels, value] of this.values) {
      lines.push(`${this.name}${labels} ${value}`);
    }
    return lines.join('\n');
  }
}

class Gauge {
  constructor(name, help, collect) {
    this.name = name;
    this.help = help;
    this.collect = collect; // () => number, evaluated at scrape time
  }

  render() {
    const value = this.collect();
    if (!Number.isFinite(value)) return '';
    return [
      `# HELP ${this.name} ${this.help}`,
      `# TYPE ${this.name} gauge`,
      `${this.name} ${value}`,
    ].join('\n');
  }
}

class Histogram {
  constructor(name, help, labelNames = [], buckets = DEFAULT_BUCKETS) {
    this.name = name;
    this.help = help;
    this.labelNames = labelNames;
    this.buckets = buckets;
    this.series = new Map();
  }

  observe(labels, seconds) {
    const key = serializeLabels(labels);
    let entry = this.series.get(key);
    if (!entry) {
      entry = { counts: new Array(this.buckets.length).fill(0), sum: 0, count: 0, labels };
      this.series.set(key, entry);
    }
    // Store the count PER bucket; render() makes them cumulative. Doing it in
    // both places double-counts and produces a histogram whose buckets exceed
    // its own _count, which silently breaks every quantile a dashboard draws.
    for (let i = 0; i < this.buckets.length; i++) {
      if (seconds <= this.buckets[i]) {
        entry.counts[i]++;
        break;
      }
    }
    entry.sum += seconds;
    entry.count++;
  }

  render() {
    if (this.series.size === 0) return '';
    const lines = [`# HELP ${this.name} ${this.help}`, `# TYPE ${this.name} histogram`];
    for (const entry of this.series.values()) {
      // Buckets are cumulative, which is what the format requires.
      let cumulative = 0;
      for (let i = 0; i < this.buckets.length; i++) {
        cumulative += entry.counts[i];
        lines.push(
          `${this.name}_bucket${serializeLabels({ ...entry.labels, le: String(this.buckets[i]) })} ${cumulative}`,
        );
      }
      lines.push(`${this.name}_bucket${serializeLabels({ ...entry.labels, le: '+Inf' })} ${entry.count}`);
      lines.push(`${this.name}_sum${serializeLabels(entry.labels)} ${entry.sum}`);
      lines.push(`${this.name}_count${serializeLabels(entry.labels)} ${entry.count}`);
    }
    return lines.join('\n');
  }
}

// ── The metric set ───────────────────────────────────────────────────────────
//
// RED (rate, errors, duration) on the HTTP surface, plus the handful of
// business signals that actually page someone: scans failing, the AI providers
// falling over, quota being refused, and abuse control firing.

const registry = [];
function register(metric) {
  registry.push(metric);
  return metric;
}

const httpRequests = register(
  new Counter('snapcal_http_requests_total', 'HTTP requests by route and status class.', [
    'method',
    'route',
    'status',
  ]),
);

const httpDuration = register(
  new Histogram(
    'snapcal_http_request_duration_seconds',
    'HTTP request latency.',
    ['method', 'route'],
    [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60],
  ),
);

const scans = register(
  new Counter('snapcal_scans_total', 'Scan attempts by outcome and answering provider.', [
    'outcome',
    'provider',
  ]),
);

const scanDuration = register(
  new Histogram('snapcal_scan_duration_seconds', 'End-to-end scan latency.', ['outcome']),
);

const quotaDenials = register(
  new Counter('snapcal_quota_denials_total', 'Requests refused for exhausted quota.', ['kind']),
);

const authFailures = register(
  new Counter('snapcal_auth_failures_total', 'Rejected requests by control.', ['control']),
);

const rateLimited = register(
  new Counter('snapcal_rate_limited_total', 'Requests refused by a rate limiter.', ['limiter']),
);

const entitlementCache = register(
  new Counter('snapcal_entitlement_cache_total', 'Entitlement cache lookups.', ['result']),
);

const firestoreOps = register(
  new Counter('snapcal_firestore_operations_total', 'Firestore operations issued by the API.', [
    'operation',
    'collection',
  ]),
);

const reminderRuns = register(
  new Counter('snapcal_reminder_notifications_total', 'Reminder notifications by outcome.', ['outcome']),
);

// Outbound socket pool. Active sockets climbing while request rate stays flat
// means connections are not being reused -- the failure this pool exists to
// prevent, and one that otherwise only shows up as ECONNRESET under load.
const { agentStats } = require('./http_agents');
register(new Gauge('snapcal_outbound_sockets_active', 'Outbound sockets in use.', () => agentStats().active));
register(new Gauge('snapcal_outbound_sockets_free', 'Idle keep-alive sockets held open.', () => agentStats().free));
register(new Gauge('snapcal_outbound_requests_queued', 'Requests waiting for a free socket.', () => agentStats().queued));

register(
  new Gauge('snapcal_process_uptime_seconds', 'Process uptime.', () => Math.round(process.uptime())),
);
register(
  new Gauge('snapcal_process_heap_used_bytes', 'V8 heap in use.', () => process.memoryUsage().heapUsed),
);
register(
  new Gauge('snapcal_process_rss_bytes', 'Resident set size.', () => process.memoryUsage().rss),
);

/**
 * Express middleware recording rate, errors and duration for every request.
 *
 * The route label is the Express route PATTERN, never the concrete URL. Using
 * `req.path` would put every uid and scanId into a distinct time series and
 * blow up cardinality on the metrics backend within a day.
 */
function httpMetricsMiddleware(req, res, next) {
  const startedAt = process.hrtime.bigint();
  res.on('finish', () => {
    const seconds = Number(process.hrtime.bigint() - startedAt) / 1e9;
    const route = (req.route && req.route.path) || req.baseUrl || 'unmatched';
    const labels = { method: req.method, route };
    httpDuration.observe(labels, seconds);
    httpRequests.inc({ ...labels, status: String(res.statusCode) });
    if (res.statusCode === 429) rateLimited.inc({ limiter: route });
  });
  next();
}

function renderMetrics() {
  return (
    registry
      .map((metric) => metric.render())
      .filter(Boolean)
      .join('\n\n') + '\n'
  );
}

module.exports = {
  httpMetricsMiddleware,
  renderMetrics,
  metrics: {
    scans,
    scanDuration,
    quotaDenials,
    authFailures,
    entitlementCache,
    firestoreOps,
    reminderRuns,
    rateLimited,
  },
  // Exported for tests.
  Counter,
  Gauge,
  Histogram,
};
