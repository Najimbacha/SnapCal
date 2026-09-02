# SnapCal operations runbook

What to watch, what to do when it fires, and how to prove a restore works.
Everything here refers to things that exist in the repository — metric names
come from `backend/metrics.js`, retention from `firestore.indexes.json` and
`scripts/storage-lifecycle.json`.

---

## 1. Metrics

The API exposes Prometheus text at `GET /metrics`, guarded by a bearer token
(`METRICS_TOKEN`). With no token set the endpoint returns 404 — it never
serves unauthenticated, because the label values describe traffic shape,
provider health and quota pressure, which is reconnaissance.

The reminder worker exposes the same format on `WORKER_METRICS_PORT` over the
private network. Scrape both: the worker is the only process that sends
notifications, and an unscraped worker is an invisible one.

### Scrape config (Grafana Cloud / any Prometheus)

```yaml
scrape_configs:
  - job_name: snapcal-api
    scrape_interval: 30s
    metrics_path: /metrics
    authorization:
      type: Bearer
      credentials: ${METRICS_TOKEN}
    static_configs:
      - targets: ['snapcal-api.onrender.com:443']
    scheme: https

  - job_name: snapcal-worker
    scrape_interval: 60s
    metrics_path: /metrics
    static_configs:
      - targets: ['snapcal-worker:9100']
```

### What is exported

| Metric | Type | Labels | Answers |
|---|---|---|---|
| `snapcal_http_requests_total` | counter | method, route, status | Rate and errors, per route |
| `snapcal_http_request_duration_seconds` | histogram | method, route | Latency, p50/p95/p99 |
| `snapcal_scans_total` | counter | outcome, provider | Which AI provider is answering, and which is failing |
| `snapcal_scan_duration_seconds` | histogram | outcome | How long a scan actually takes |
| `snapcal_quota_denials_total` | counter | kind | Free-tier pressure; a proxy for upgrade intent |
| `snapcal_auth_failures_total` | counter | control | Which control is rejecting, and whether that is normal |
| `snapcal_rate_limited_total` | counter | limiter | Abuse control firing — or false-positiving |
| `snapcal_entitlement_cache_total` | counter | result | Whether the Redis cache is doing its job |
| `snapcal_firestore_operations_total` | counter | operation, collection | Read volume, before the bill tells you |
| `snapcal_reminder_notifications_total` | counter | outcome | Reminders sent, rejected, pruned |
| `snapcal_outbound_sockets_active` | gauge | — | Connections to AI providers in use |
| `snapcal_outbound_sockets_free` | gauge | — | Idle connections held for reuse |
| `snapcal_outbound_requests_queued` | gauge | — | Calls waiting for a free socket |

Two `snapcal_scans_total` outcomes are worth knowing by name: `shed` means an
instance refused a scan because it was already at its concurrency ceiling, and
`provider_skipped` means a circuit breaker was open and that provider was not
even tried.

The `route` label is always the Express route **pattern**, never the concrete
URL. Putting uids and scanIds in a label would create a new time series per
user and take the metrics backend down within a day.

---

## 2. Alerts

Ordered by what actually wakes someone. Thresholds are starting points —
tighten them once you have a fortnight of real data.

```yaml
groups:
  - name: snapcal
    rules:
      # The core feature is down. This is the one that matters: a total scan
      # outage was once found by a human trying the app, not by a monitor.
      - alert: ScanFailureRateHigh
        expr: |
          sum(rate(snapcal_scans_total{outcome="failure"}[10m]))
          / clamp_min(sum(rate(snapcal_scans_total{outcome=~"success|failure"}[10m])), 0.001)
          > 0.25
        for: 10m
        labels: { severity: page }
        annotations:
          summary: "More than a quarter of scans are failing"
          runbook: "Check /health for configured providers; then §4."

      # Every provider in the chain is erroring. Distinct from the above:
      # this fires before users have burned enough quota to notice.
      - alert: AllVisionProvidersFailing
        expr: |
          sum(rate(snapcal_scans_total{outcome="provider_ok"}[10m])) == 0
          and sum(rate(snapcal_scans_total{outcome="provider_error"}[10m])) > 0
        for: 5m
        labels: { severity: page }

      - alert: ApiErrorRateHigh
        expr: |
          sum(rate(snapcal_http_requests_total{status=~"5.."}[5m]))
          / clamp_min(sum(rate(snapcal_http_requests_total[5m])), 0.001)
          > 0.02
        for: 10m
        labels: { severity: page }

      - alert: ApiLatencyP95High
        expr: |
          histogram_quantile(0.95,
            sum by (le) (rate(snapcal_http_request_duration_seconds_bucket{route!="/v1/scan"}[10m]))
          ) > 1
        for: 15m
        labels: { severity: ticket }
        annotations:
          summary: "p95 above 1s on light endpoints"
          note: "/v1/scan is excluded on purpose — it is bounded by an upstream model, not by us."

      # The cache is meant to absorb the launch burst. A collapsed hit rate
      # means Redis is down or the TTL is being invalidated too aggressively,
      # and Firestore reads are about to multiply.
      - alert: EntitlementCacheHitRateLow
        expr: |
          sum(rate(snapcal_entitlement_cache_total{result="hit"}[15m]))
          / clamp_min(sum(rate(snapcal_entitlement_cache_total[15m])), 0.001)
          < 0.5
        for: 30m
        labels: { severity: ticket }

      # Rate limiting exists to protect the AI bill. A spike is either an
      # attack or a false positive against real users; both need a human.
      - alert: RateLimitingSpike
        expr: sum(rate(snapcal_rate_limited_total[5m])) > 5
        for: 10m
        labels: { severity: ticket }

      # App Check rejections at volume mean either a broken release or
      # someone hitting the API without the app.
      - alert: AppCheckRejectionsHigh
        expr: sum(rate(snapcal_auth_failures_total{control=~"appcheck_.*"}[10m])) > 1
        for: 15m
        labels: { severity: ticket }

      # Silence is the failure mode here. The worker runs three times a day,
      # so absence of sends over a day means it is not running at all.
      - alert: RemindersNotSending
        expr: sum(increase(snapcal_reminder_notifications_total{outcome="sent"}[24h])) == 0
        for: 1h
        labels: { severity: ticket }
        annotations:
          summary: "No reminders sent in 24h"
          note: "Check the worker is up and that the backfill has run — see §5."

      # Sockets climbing while request rate is flat means connections are not
      # being reused. Left alone this ends as ECONNRESET under load, which
      # looks exactly like a provider outage but is entirely self-inflicted.
      - alert: OutboundSocketsClimbing
        expr: snapcal_outbound_sockets_active > 100
        for: 15m
        labels: { severity: ticket }

      # Shedding is correct behaviour, but sustained shedding means the fleet
      # is too small, not that the ceiling is wrong. Add instances first.
      - alert: ScansBeingShed
        expr: sum(rate(snapcal_scans_total{outcome="shed"}[10m])) > 0.2
        for: 10m
        labels: { severity: ticket }

      - alert: WorkerDown
        expr: up{job="snapcal-worker"} == 0
        for: 10m
        labels: { severity: ticket }
```

Keep the existing uptime check on `/health` as well. It returns 503 on a
sustained scan failure rate, so it catches the same outage from outside your
metrics stack — which is what you want when the metrics stack is the thing
that broke.

---

## 3. Retention

Three unbounded collections were going to become the largest thing in the
database. All three are now bounded, and none of the bounds are automatic:
each needs a deploy or a one-off command.

> **On the Spark (free) plan, the first three of these are unavailable.** TTL
> deletes, scheduled backups, PITR and managed exports all require billing to
> be enabled — not as a volume threshold, but as a feature gate. The TTL
> policies are therefore parked in `firestore.indexes.ttl.json` and are NOT in
> the deployed `firestore.indexes.json`. The server still writes `expiresAt` on
> every record, so the day billing is enabled the policies can be deployed and
> take effect on data already stored. See §4 for what to do about backups in
> the meantime.

| Data | Bound | Mechanism | How to apply |
|---|---|---|---|
| `auditLogs` | 365 days | Firestore TTL on `expiresAt` | Blaze only: copy `firestore.indexes.ttl.json` over `firestore.indexes.json`, then `firebase deploy --only firestore:indexes` |
| `revenueCatEvents` | 90 days | Firestore TTL on `expiresAt` | same deploy |
| Scan images | 30 days | GCS lifecycle on the `scans/` prefix | `gcloud storage buckets update gs://snapcal-ef333.firebasestorage.app --lifecycle-file=scripts/storage-lifecycle.json` |

Notes that matter:

- **Writing `expiresAt` does nothing on its own.** Until the TTL policy is
  deployed the field is just a stored date. Verify in the Firebase console
  under Firestore → TTL that both policies read *Serving*.
- **The 90 days on `revenueCatEvents` is a correctness bound, not a cost one.**
  That collection is the webhook idempotency guard. Shorten it below
  RevenueCat's retry window and a replayed event gets processed twice.
- **Scan images live under `scans/{uid}/...`, not `users/{uid}/scans/...`.**
  A GCS lifecycle rule matches an object-name prefix and cannot wildcard a
  path segment, so the old layout could not be expired without also matching
  progress photos, which must be kept forever. Objects still under the legacy
  prefix need a one-off sweep; there should be very few.
- Deletion is permanent and applies to existing objects the moment the
  lifecycle policy lands. `scripts/storage-lifecycle.README.md` explains the
  policy; the `.json` beside it is comment-free and carries only the `rule`
  key on purpose, because `gcloud` rejects anything else.

---

## 4. Backup and restore

### On the Spark plan: manual local backups

Firestore's own backups need billing. Until then, `npm run backup` in
`backend/` reads every user document and writes a timestamped JSON copy to
`backups/` (gitignored — it holds every user's data in plain text).

```
cd backend
npm run backup -- --key=path\to\serviceAccount.json
```

Three things to understand about it:

- **Every document copied costs one read** against the 50,000/day free tier.
  The script stops at 25,000 by default so it cannot exhaust the allowance and
  take the live app down. Run it when the app is quiet.
- **A partial backup announces itself.** If the budget runs out the manifest
  says `complete: false` and the script exits non-zero. Do not treat that file
  as a backup.
- **There is no restore script, deliberately.** A restore overwrites live data,
  and a tool that can do that by accident is worse than the problem. The files
  are plain JSON keyed by document path; restoring one user is a small,
  deliberate edit made while looking at the data.

This is materially worse than managed backups — it is manual, has no schedule,
no retention, and lives on one laptop. It is also the difference between losing
everything and losing a day. Run it before any risky change, and on a calendar
reminder otherwise.

### Once billing is enabled

1. **Point-in-time recovery** on Firestore — 7 days of continuous backup:
   `gcloud firestore databases update --enable-pitr`
2. **Scheduled exports** to a GCS bucket, daily, retained 30 days:
   ```
   gcloud firestore backups schedules create \
     --database='(default)' --recurrence=daily --retention=30d
   ```
3. A separate bucket for exports, with its own lifecycle rule. Do not put
   backups in the bucket that holds the data.

### The restore drill — run monthly

A backup nobody has restored is a hypothesis. The drill exists to turn it
into a fact, and to keep the steps in someone's muscle memory before the day
they are needed.

1. Create (or reuse) a **staging** Firebase project. Never restore into
   production to test a restore.
2. Restore the most recent scheduled export into it:
   ```
   gcloud firestore import gs://<export-bucket>/<timestamp> --database='(default)'
   ```
3. Verify, and write the numbers down:
   - document counts for `users`, and a spot check of one user's
     `subscription/current` and `usage/currentMonth`;
   - that `settings/app` documents carry `lastFoodReminderDate`;
   - that a known Pro account still reads as active.
4. Point a local backend at staging and confirm `/health` returns 200 and a
   scan succeeds end to end.
5. Record the wall-clock time the restore took. That number is your real
   RTO — the one to quote, rather than an estimate.
6. Tear the staging data down.

If a step fails, the drill has done its job. Fix it that week.

---

## 5. Load testing

`scripts/loadtest.js` is a k6 script modelled on the audit's traffic estimates.
Run it against staging, never production, and seed it with **hundreds** of
Firebase ID tokens — one token measures your cache, not your capacity.

```
k6 run -e BASE_URL=https://staging-host \
       -e TOKENS=./tokens.txt \
       -e APPCHECK_TOKEN=<staging debug token> \
       scripts/loadtest.js
```

It runs light traffic and scans as separate scenarios on purpose: averaging
thousands of short requests together with a few dozen sockets held open for
tens of seconds hides the one thing you are testing for — whether a slow scan
starves everything else. The assertion that matters is `p95 < 400ms` on the
light scenario while scans are in flight.

You do not test a million users. You test the per-user request pattern at peak
requests-per-second and multiply.

---

## 6. Known operational gotchas

- **The reminder worker must run exactly one replica.** Two replicas means
  every user is notified twice. `render.yaml` pins `numInstances: 1`; the API
  service cannot start a scheduler at all.
- **The reminder query only sees documents that have `serverReminderSentOn`.**
  Firestore excludes documents missing the field from a range filter. New
  users are seeded by the register endpoint; users who predate that change
  need `npm run backfill:reminder-date` run once against production, or they
  are silently invisible to reminders forever.
- **`serverReminderSentOn` is named that way on purpose.** The obvious name,
  `lastFoodReminderDate`, is a field every released app writes on every
  settings save — usually as null. Any rule strong enough to stop that from
  erasing the worker's record also rejects the whole settings document from
  those apps. Using a name no shipped client knows about means the rules and
  the app release are independent: they can be deployed in either order, and
  older installs keep syncing normally. `lastFoodReminderDate` still exists,
  is still writable, and is read by nothing.
- **Redis is a cache, never a source of truth.** It is configured
  `allkeys-lru`, so eviction is normal. Losing it degrades performance and
  makes rate limits per-instance again; it does not lose data and must never
  fail a request.
- **A 503 with `Retry-After` on `/v1/scan` is deliberate.** The instance was
  at its scan ceiling and shed the request so the load balancer could place it
  elsewhere. Sustained shedding means add instances; it is not a bug to tune
  away by raising `MAX_CONCURRENT_SCANS`, which only trades a fast refusal for
  a slow failure.
- **`/health` reporting `shutting_down` during a deploy is normal.** The
  process stops passing health checks first so traffic drains away, then
  finishes in-flight scans, then exits. Seeing it outside a deploy means
  something is restarting the process.
- **A provider showing `open` under `providers.breakers` in `/health` is being
  skipped.** It failed repeatedly, so scans no longer wait on it. It retries
  itself after a minute; no action needed unless it never closes.
- **Meal sync is incremental, and the cursor lives in the meal index box.**
  Each device remembers when it last synced and asks only for meals written
  since. A device with no cursor takes a one-off 30-day pull instead, because
  meals written by older app versions have no `updatedAt` and Firestore
  excludes documents missing a field from a range filter. If Firestore read
  volume ever jumps back up without a matching jump in users, check that
  `updatedAt` is still in the `validMeal` allowlist — losing it rejects every
  meal write and quietly forces every device back to full pulls.
- **Settings sync is throttled to once per six hours per device.** A first
  sync for an account on a device is never skipped — that is how a new install
  gets the user's data — and it alone reads the legacy blob on the user root.
  The freshness stamp lives in SharedPreferences under `<uid>:settingsCloudSyncAt`
  and is cleared on logout; if a user ever reports settings reverting to
  defaults after signing back in, that stamp surviving a local wipe is the
  first thing to check.
- **The free tier caps Firestore at 50,000 document reads per day.** That
  ceiling, not the monthly bill, is the binding constraint while the project is
  on Spark. The incremental meal and settings sync exist largely to stay under
  it: before them a single app launch cost roughly 94 reads, which is about 530
  launches — on the order of 150-200 daily users — before the app stops
  working. Any change that reintroduces a per-launch full collection read
  breaks the app at a size you can reach in a week, not at a million users.
- **`/metrics` unset is off, not open.** If a scrape returns 404, the token is
  missing on that service, not the endpoint.
