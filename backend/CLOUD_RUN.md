# Wazn: owner guide for moving to Cloud Run

Prepared against Google documentation on 19 September 2026 and updated after
the production cutover on 20 September 2026. Cloud Run now serves the API and
Firebase Remote Config template v9 points `backend_proxy_url` at it, so existing
installed apps can receive the new endpoint. Render remains the rollback target,
and the Android fallback URL intentionally still points to Render. RevenueCat
and reminder-scheduler destination changes remain separate owner checks.

### Implementation verification (20 September 2026)

| Check | Result |
| --- | --- |
| Backend regression suite, local Node 24.18.0 | 170 passed, 0 failed, 1 skipped |
| PowerShell deployment/budget tests with mocked cloud APIs | Passed: read-only preflight, deploy flags, setting verification, incorrect-region/max rejection, temporary-file cleanup, budget create/update |
| Scan burst, 20 requests with 1MiB images | 136MiB peak backend RSS before the admission improvement; no unexpected responses |
| Scan burst, 20 requests with 10MiB images | Peak reduced from 807MiB to 576MiB by admitting before parsing; 1Gi selected |
| Pinned Node 24.21.0 Alpine image | Docker Hub manifest verified; Linux amd64 available |
| Two-process shared Redis integration | Skipped: no disposable Redis available locally; mandatory before cutover |
| Container build, image-content audit | Pending: local Docker engine unavailable |
| Live Cloud Run deployment | `snapcal-api` revision `snapcal-api-00001-tzr`, `us-central1`; service settings and `/health` verified |
| Shared production Redis | TLS Upstash Redis connected; Cloud Run health reports the shared cache ready |
| Existing Android installation | Real scan, AI coach and premium-status requests completed successfully through Cloud Run |
| Firebase Remote Config | Template v9 published with the Cloud Run base URL; pre-cutover template saved outside Git |
| RevenueCat webhook and reminder scheduler | Still require destination verification; do not retire Render yet |

Local checks do not establish production readiness. Complete the pending gates
below before changing `backend_proxy_url`.

## 1. What you are paying for

The deployment keeps one instance warm, caps the **service** at three instances,
uses one CPU, request-based billing, concurrency 20 and a 120-second request
timeout. Scan work is admitted before image parsing, at ten scans per instance.
The template uses **1Gi memory**: local mocked load testing of twenty simultaneous
10MiB images exceeded 512Mi even after reducing unnecessary buffering. Small
images alone are not sufficient evidence to choose 512Mi. Verify container memory
with real Android uploads before release; 512Mi remains a supported configuration
only when representative worst-case testing stays below 410Mi.

The $25 monthly budget is an **alert target, not a price estimate or spending cap**.
Alerts at $12.50, $20 and $25 cover this entire Google project, including existing
Firebase usage, builds, Artifact Registry, logs and network traffic. External AI
provider charges and external Redis charges are separate. Request-based billing
still charges for the warm instance while idle. Three continuously busy instances
can cost substantially more than $25. Google can briefly exceed the instance limit.

Rate limits, App Check, shared Redis counters and transactional scan allowances
reduce abuse; none guarantee a fixed bill. Pro users retain their existing paid
allowances, so their AI usage still needs provider-side monitoring. Do not add an
automatic billing shutdown: that can also disable Firebase for existing users.

## 2. Owner setup, before deployment

Install the current [Google Cloud CLI](https://docs.cloud.google.com/sdk/docs/install),
sign in with your owner account, and enable billing on `snapcal-ef333` in the console.
Do not send credentials in chat or save them in Git. Run these PowerShell commands
from the repository root. Stop if any command fails.

```powershell
gcloud auth login
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com firestore.googleapis.com firebaseappcheck.googleapis.com fcm.googleapis.com identitytoolkit.googleapis.com cloudbilling.googleapis.com billingbudgets.googleapis.com monitoring.googleapis.com --project=snapcal-ef333
gcloud firestore databases describe --database='(default)' --project=snapcal-ef333 --format='value(locationId)'
```

Copy `backend/deploy/cloud-run.example.json` to `backend/deploy/cloud-run.local.json`.
The local filename is ignored by Git. Enter the actual Firestore location and its
matching Cloud Run region: `nam5` → `us-central1`, `eur3` → `europe-west1`, or the same
region for a regional database. An unrecognized multi-region needs explicit review,
not a guessed region. The script verifies against the live database.

Compare the template's public settings with the **live Render environment**.
The template mirrors the repository's current DeepSeek/v2 configuration, 15 free
monthly scans, maximum 10 monthly bonus scans, one free daily coach message and
30 total free daily AI requests. Keep actual production model/provider overrides
and browser origins where they differ. Add any additional provider keys as Secret
Manager references, not plain environment values. App Check must remain enabled.

### Runtime identity and build identity

Create the runtime identity once. If it already exists, inspect/reuse it rather
than creating duplicates. The custom role intentionally has no IAM, billing,
project administration or ability to mint tokens. Admin-only SDK operations beyond
the deployed API (for example the separate set-admin script) are not granted.

```powershell
gcloud iam service-accounts create snapcal-run --display-name='Wazn API runtime' --project=snapcal-ef333
gcloud iam roles create snapcalRuntime --file=backend/deploy/runtime-role.yaml --project=snapcal-ef333
gcloud projects add-iam-policy-binding snapcal-ef333 --member='serviceAccount:snapcal-run@snapcal-ef333.iam.gserviceaccount.com' --role='projects/snapcal-ef333/roles/snapcalRuntime'
gcloud storage buckets add-iam-policy-binding gs://snapcal-ef333.firebasestorage.app --member='serviceAccount:snapcal-run@snapcal-ef333.iam.gserviceaccount.com' --role=roles/storage.objectUser
```

If the custom role already exists, use `gcloud iam roles update` with the same
file. Confirm the bucket name against production before granting its scoped role.
The backend uses application-default credentials from this attached identity;
do not set `FIREBASE_SERVICE_ACCOUNT` or upload a Firebase private key to Cloud Run.

The deploying account needs Cloud Run source deployment permissions, permission
to set public invocation, and Service Account User on the runtime identity.
An owner can perform this deployment. The build identity needs `roles/run.builder`
on this project. Discover it instead of assuming its email:

```powershell
gcloud builds get-default-service-account --project=snapcal-ef333
```

Grant `roles/run.builder` to the account returned, using IAM in the console. Do
not grant build permissions to the runtime identity or use Editor to fix access
errors. Source deployment creates its Artifact Registry repository if missing;
do not grant the runtime identity access to build source or images unnecessarily.

### Secrets and Redis

In Secret Manager, create these secrets with values copied directly from Render:

| Secret ID | Backend environment variable |
| --- | --- |
| `snapcal-deepseek` | `DEEPSEEK_API_KEY` |
| `snapcal-revenuecat-webhook` | `REVENUECAT_WEBHOOK_AUTH` |
| `snapcal-revenuecat-api` | `REVENUECAT_SECRET_API_KEY` |
| `snapcal-redis-url` | `REDIS_URL` |
| `snapcal-scheduler` | `SCHEDULER_SECRET` |
| `snapcal-metrics` | `METRICS_TOKEN` |

Preserve the entire webhook Authorization value, including any `Bearer ` prefix.
Grant `roles/secretmanager.secretAccessor` to the runtime account **on each secret**,
not the whole project. For example:

```powershell
gcloud secrets add-iam-policy-binding snapcal-deepseek --member='serviceAccount:snapcal-run@snapcal-ef333.iam.gserviceaccount.com' --role=roles/secretmanager.secretAccessor --project=snapcal-ef333
```

Repeat for every configured secret. Set each reference in the local config to the
actual enabled numeric version, e.g. `snapcal-deepseek:2`. Avoid `latest`, because a
secret rotation should be a deliberate revision. Never put secret values in the
JSON, CLI arguments, logs, screenshots or Git. Secret names are not secret values.

Cloud Run requires a reachable **TLS `rediss://` endpoint**. Render private hostnames
will not work across clouds. Verify the existing Redis provider supports secure
external access and permits Cloud Run connections. Cloud Run does not have a fixed
outbound IP by default; do not open a private Redis instance to the world or add
a paid VPC/NAT stack just to work around this. If secure access requires a replacement,
stop and price it for the owner before provisioning. Share the same counter/cache
service between Render and Cloud Run during overlap. Do not use instance-local
counters. An outage returns 503 with Retry-After, including on webhooks, which
must be retried by RevenueCat. Recovery must be tested before cutover.

### Budget alerts (do this before deploying)

Create an **email** notification channel in Cloud Monitoring for the owner's email,
confirm it is enabled, and test delivery. Copy its resource name. With the billing
account ID from Billing, run:

```powershell
./backend/deploy/set-budget.ps1 -BillingAccount 'YOUR-BILLING-ACCOUNT-ID' -OwnerEmailChannel 'projects/snapcal-ef333/notificationChannels/CHANNEL-ID'
./backend/deploy/set-budget.ps1 -BillingAccount 'YOUR-BILLING-ACCOUNT-ID' -OwnerEmailChannel 'projects/snapcal-ef333/notificationChannels/CHANNEL-ID' -Apply
```

The first command checks configuration. The second creates or updates one named
project-wide monthly budget and verifies thresholds and recipient. It does not
create a second budget on repeat runs. This template uses USD; if the billing account
uses a different currency, stop and choose the equivalent alert amount with the
owner. **Alerts warn; they never hard-stop this deployment's spending.**

## 3. Local verification and deployment

```powershell
Push-Location backend
npm ci
node --test 'test/**/*.test.js'
node scripts/check-cloud-run-load.js 1
node scripts/check-cloud-run-load.js 10
Pop-Location
./backend/test/deployment_scripts.test.ps1
```

The load script runs the real scan route in an isolated process with mocked Firebase
and AI, sends 20 requests, checks successful or retryable responses, and reports
backend peak RSS. It never makes paid AI calls. It is not a substitute for container
limits, real images, provider latency or Firestore permission tests.

For the shared-counter deployment gate, start a **disposable local Redis**:

```powershell
docker run --rm -d --name snapcal-migration-redis -p 127.0.0.1:16379:6379 redis:7.4-alpine
$env:TEST_REDIS_URL = 'redis://127.0.0.1:16379'
node --test backend/test/shared_redis.integration.test.js
Remove-Item Env:TEST_REDIS_URL
docker stop snapcal-migration-redis
```

The test starts two separate backend limiter processes with a unique expiring
test prefix, checks a shared allowance and a disconnect. Do not point it at
production Redis. Skipped means **not verified**, not passed.

With Docker running, build `docker build -t snapcal-cloud-run-check ./backend`.
Check the image contains the nutrition JSON, legal pages and runtime modules, and
no `.env`, credentials, test fixtures or deployment files. `.gcloudignore` also
restricts source uploads. From `backend`, inspect `gcloud meta list-files-for-upload`
before the first source deployment. The exact Node patch tag is pinned; verify it
can be pulled before release. No successful local image build has been assumed.

```powershell
./backend/deploy/deploy-cloud-run.ps1 -ConfigPath backend/deploy/cloud-run.local.json
./backend/deploy/deploy-cloud-run.ps1 -ConfigPath backend/deploy/cloud-run.local.json -Action Deploy
./backend/deploy/deploy-cloud-run.ps1 -ConfigPath backend/deploy/cloud-run.local.json -Action Verify
```

Default action is read-only preflight. Deploy builds only the backend source and
verifies the **service-level** min/max, billing, CPU, memory, concurrency, timeout,
runtime identity, `/startup`, `/health`, Redis connectivity and RevenueCat settings.
It does not publish Remote Config or edit any third-party configuration. Save the
service URL and revision name in your operations notes. Never switch users after
a failed verification. A green `/health` confirms configuration and cache readiness,
not full Firebase/AI access.

Cloud Run replaces idle instances occasionally even with min=1. Shutdown defaults
on Cloud Run use no initial delay and a nine-second deadline, versus the preserved
Render defaults. A forced termination can still interrupt a scan and its best-effort
quota refund. Test retries and check quota records; this migration does not introduce
a durable job queue or promise exactly-once processing.

## 4. Mandatory live checks and safe cutover

Record pass/fail, time, revision and test-account ID for each check. Keep production
credentials out of the record.

- Using an Android test build with the new URL, test a real scan, image analysis,
  AI coach, meal planner, free limits and a paying user's premium status. Use an
  isolated Remote Config condition or test-only URL override, not a global URL
  change to perform the test. Missing/invalid Firebase token and App Check must fail.
- Check `/terms`, `/privacy`, `/account-deletion`; test account deletion with a
  disposable user to verify the new identity's Auth, Storage and Firestore access.
- Send RevenueCat sandbox deliveries, including a duplicate event, renewal and
  expiration; check the Firestore entitlement and cache invalidation. Verify an
  invalid webhook secret is rejected. Replay failed events after a Redis outage.
- Test rate-limit isolation for two users, and that exceeding a limit produces
  429. Validate client-IP handling from the real Cloud Run proxy; do not trust a
  client-supplied forwarding header or assume mobile carrier IPs identify a user.
- Test real image bursts at concurrency 20. Check peak memory, 5xx and retries;
  keep the 1Gi setting unless a representative worst case justifies lowering it.
- Check a reminder with a test user, and that its fan-out completes within 120s.
  The existing external scheduler remains the only scheduler. After checks pass,
  change that one job's URL and preserve its secret and schedule. Do not start
  `worker.js` inside Cloud Run or add a second cron. A timeout blocks reminder
  cutover pending a separate batch/job design.
- Leave the service untouched for at least 20 minutes, then scan again. Compare
  latency with Render; do not run an uptime ping during this idle test.

Before cutover, export the Firebase Remote Config template (including conditions)
and record the current Render URL, RevenueCat destination, scheduler destination
and Cloud Run revision. Do not include shared secrets in the backup notes.

1. Set the existing RevenueCat webhook destination to
   `https://YOUR-CLOUD-RUN-HOST/api/revenuecat/webhook`, preserving its auth header.
   Confirm successful deliveries and subscription state. Both backends share Firebase.
2. Publish the Cloud Run base URL as `backend_proxy_url` in Firebase Remote Config.
   Review conditional values too; an old override may keep a group on Render.
3. Restart an already-installed Android app and confirm it fetches the URL and
   scans with the same account and Pro status. Config activation is not instantaneous:
   requests before initialization or after fetch failure can still use Render.
4. After the Cloud Run revision containing `/v1/text-scan` is healthy and the
   Android voice flow has passed internal testing, create the Remote Config boolean
   `voice_logging_enabled` with default `false`. Enable it only for testers first,
   then publish `true` for production. Turning it off hides Voice Log without
   affecting photo, barcode, manual logging, or already-saved meals.
5. Monitor scan latency/failures, Redis, 429/503 rates, memory, RevenueCat delivery,
   reminder delivery and Billing daily for 14 days. Configure Monitoring notifications
   for sustained errors and memory pressure to the owner's channel. Keep logs free
   of images/tokens and use finite retention; review Artifact Registry storage and
   retain rollback images before choosing cleanup rules.

If scan/auth/subscription failures appear after switching, restore the saved Remote
Config template, RevenueCat URL and (if moved) scheduler URL. Verify Render health
first and recheck deliveries. Users with a cached Cloud Run URL may stay there until
the next fetch, so keep Cloud Run operational while rollback propagates. For a later
bad backend revision, route Cloud Run traffic back to the previous known-good revision
and re-run verification. Do not disable billing as a rollback mechanism.

## 5. Later Android release and Render retirement

Only after stable operation, change `AppConstants.defaultBackendProxyUrl` in
`lib/core/constants/app_constants.dart` and release through Google Play. Keep Render
for **at least 14 days**, and longer if old app versions, cached configuration or
published legal links still use it. Retirement is a separate owner decision, not
an automatic action in these scripts. Do not push these changes without permission.

## Documentation checked

- [Cloud Run deployment flags](https://docs.cloud.google.com/sdk/gcloud/reference/run/deploy)
- [Service maximum instances](https://docs.cloud.google.com/run/docs/configuring/max-instances)
- [Minimum instances and idle billing](https://docs.cloud.google.com/run/docs/configuring/min-instances)
- [Cloud Run pricing](https://cloud.google.com/run/pricing)
- [Container lifecycle and shutdown](https://docs.cloud.google.com/run/docs/container-contract)
- [Source deployment and build permissions](https://docs.cloud.google.com/run/docs/deploying-source-code)
- [Budget alerts](https://docs.cloud.google.com/billing/docs/how-to/budgets)
- [Budget create](https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/create) / [update](https://docs.cloud.google.com/sdk/gcloud/reference/billing/budgets/update)
- [Node release schedule](https://github.com/nodejs/Release)
