# SnapCal

SnapCal is an AI calorie counter: snap a photo of your food and the app
identifies it, estimates nutrition, and tracks your daily calories, macros,
water and weight.

- **Flutter** app (Android + iOS) in `lib/`
- **Node.js/Express** backend proxy for all AI providers in `backend/`
- **Firebase**: Auth, Firestore, Storage, App Check, Crashlytics, FCM,
  Remote Config
- **RevenueCat** for subscriptions (`pro` entitlement)

## Prerequisites

- Flutter (stable channel) — see [flutter.dev](https://docs.flutter.dev/get-started/install)
- Node.js >= 18
- A Firebase project with a Android/iOS apps registered
  (`firebase.json`, `android/app/google-services.json`,
  `ios/Runner/GoogleService-Info.plist`)
- [Melos-free] standard Flutter tooling; codegen uses `build_runner`

## Getting started

```bash
flutter pub get
flutter run            # debug build on a connected device/emulator
```

Regenerate code (Riverpod generators, Hive adapters are committed):

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run tests:

```bash
flutter test                        # app unit/widget tests
cd backend && npm install && npm test   # backend unit/security tests
```

## Backend setup (`backend/`)

```bash
cd backend
npm install
npm start
```

All configuration is via environment variables (or a `.env` file).
**The security-relevant ones are mandatory in production:**

| Variable | Required | Meaning |
| --- | --- | --- |
| `REQUIRE_APP_CHECK` | **Yes in prod** | Must be `true` in production — the server *refuses to boot* when App Check is disabled there. Defaults to enabled. |
| `ALLOWED_ORIGINS` | Recommended | Comma-separated browser origin allow-list. Empty denies all browser origins (native apps unaffected). |
| `REVENUECAT_WEBHOOK_AUTH` | Yes | Shared secret for `/api/revenuecat/webhook`. |
| `FIREBASE_SERVICE_ACCOUNT` | One of the two | Service-account JSON for Firebase Admin. |
| `GOOGLE_APPLICATION_CREDENTIALS` | One of the two | Application-default credentials path. |
| `GEMINI_API_KEYS` / `DEEPSEEK_API_KEY` / `OPENROUTER_API_KEY` / `QWEN_API_KEY` / `GROQ_API_KEY` | At least one | AI vision/text provider keys, tried in fallback order. |
| `FREE_MONTHLY_SCANS` | Optional | Free-tier scan limit per UTC month (default `3`). |
| `SCAN_PIPELINE` | Optional | `v1` (AI writes nutrition) or `v2` (AI detects, DB computes). |
| `PORT`, `TRUST_PROXY_COUNT`, `API_RATE_LIMIT`, `SCAN_RATE_LIMIT`, `WEBHOOK_RATE_LIMIT` | Optional | Operational tuning. |

Client apps receive the backend URL through `ConfigService` /
Remote Config; the compile-time default lives in
`lib/core/constants/app_constants.dart`.

## Project layout

```
lib/
  core/          resilience layer, security service, theme, utils
  data/          models (Hive), repositories, services
  planner/       pure planner math (portion fitting, grocery aggregation)
  providers/     Riverpod state
  screens/       feature screens
backend/
  server.js      Express API (scans, entitlements, webhooks, admin)
  services/      nutrition DB provider, reminder fan-out
  cron/          scheduler
security-tests/  Firestore rules unit tests (@firebase/rules-unit-testing)
firestore.rules  deny-by-default rules — deploy after model changes
storage.rules    UID-scoped storage rules
```

## Conventions worth knowing

- **Server-authoritative entitlements.** The client never decides Pro;
  `users/{uid}/subscription/current` is written only by the backend
  (RevenueCat webhook / admin). Firestore rules reject client writes to
  subscription/usage documents.
- **Local data is user-scoped.** Hive boxes are AES-encrypted with a key in
  platform secure storage. Sign-out wipes every user-scoped box and
  preference key (`SessionCleanupService`); account deletion additionally
  deletes the encryption key.
- **Model ↔ rules contract.** When you add a field to a Hive model that is
  mirrored into Firestore, update `firestore.rules` AND
  `security-tests/firestore.rules.test.js`; the tests assert the real
  serialised payloads so a model change fails CI instead of silently
  dropping every write in production.
