<p align="center">
  <img src="assets/icon/icon.png" alt="Wazn app icon" width="96" height="96" />
</p>

<h1 align="center">Wazn</h1>

<p align="center">
  AI-powered calorie tracking for people who want to log food without typing every ingredient.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Android--first-19B98A?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Cloud%20Sync-FFCA28?style=for-the-badge&logo=firebase&logoColor=111111" />
  <img alt="RevenueCat" src="https://img.shields.io/badge/RevenueCat-Pro%20Subscriptions-6E56CF?style=for-the-badge" />
</p>

Wazn lets users snap a meal or describe it by voice, get an AI nutrition estimate, review detected foods, and save calories/macros into a daily food log. The app also includes barcode scanning, meal planning, hydration/activity tracking, an AI nutrition coach, subscriptions, reminders, and secure cloud sync.

> Android is the primary target right now. iOS support exists in the codebase, but current product work is Android-first.

---

## At a glance

| Product | Engineering |
| --- | --- |
| AI food scan from camera | Flutter + Riverpod mobile app |
| Voice meal logging with editable transcript | Native Android speech recognition + protected text-scan API |
| Personalized regional Quick Add | Offline curated catalogue + local meal-history ranking |
| Barcode lookup for packaged food | Node.js / Express backend |
| Daily calorie, macro, hydration, and activity tracking | Firebase Auth, Firestore, Storage, FCM, App Check |
| AI coach and meal planning | Backend-proxied AI providers |
| Pro subscription experience | RevenueCat + server-authoritative entitlements |

---

## What Wazn does

- Camera-based AI food scanning
- Voice meal logging with a review-before-analysis transcript
- One-tap Quick Add using recent, frequent, favorite, and regional foods
- Barcode lookup for packaged food
- Daily calories, macros, meals, hydration, activity, and weight tracking
- AI nutrition coach for meal and goal guidance
- Meal planner with grocery-style planning support
- Food log with scanned and manually added meals
- Health Connect activity integration on Android
- Achievements and streaks
- Progress reports that can be exported as PDF
- Android home-screen widget
- English, Arabic, Spanish, and French
- RevenueCat-powered Pro subscription flow
- Firebase-backed auth, sync, notifications, crash reporting, and remote config

---

## Product flow

```text
Open app
  ↓
Check daily calories + macros
  ↓
Tap camera
  ↓
Choose photo, barcode, or voice
  ↓
Capture or describe the meal
  ↓
AI detects foods + estimates nutrition
  ↓
Review result
  ↓
Add to food log
```

---

## Tech stack

| Area | Technology |
| --- | --- |
| App | Flutter / Dart |
| State | Riverpod |
| Navigation | GoRouter |
| Local storage | Hive + secure storage + lightweight preferences |
| Camera | `camera`, `image_picker`, `mobile_scanner` |
| Voice | `speech_to_text` using Android speech recognition |
| Charts/UI | `fl_chart`, `flutter_animate`, `lucide_icons`, Material |
| Backend | Node.js / Express |
| Hosting | Google Cloud Run (Render is kept only for older app versions) |
| AI | Backend-proxied AI providers, DeepSeek by default with Gemini and others as fallbacks |
| Languages | English, Arabic, Spanish, French |
| Reports | PDF export with `pdf` + `printing` |
| Auth & cloud | Firebase Auth, Firestore, Storage |
| Security | Firebase App Check, server-authoritative entitlements |
| Monetization | RevenueCat |
| Notifications | FCM + local notifications |
| Android health | Health Connect via `health` package |

---

## Repository layout

```text
lib/
  core/          App constants, theme, resilience, networking, utilities
  data/          Models, repositories, services, sync, AI/barcode clients
  l10n/          Translations (English, Arabic, Spanish, French)
  planner/       Meal-planning and nutrition conversion logic
  providers/     Riverpod app state
  screens/       App screens and feature UI
  widgets/       Shared UI components

backend/
  server.js      Express API for scans, entitlements, webhooks, admin tools
  services/      AI providers, cost controls, nutrition DB, reminders
  cron/          Scheduled jobs
  deploy/        Cloud Run deploy and budget scripts
  scripts/       Admin, backup, and data-import tools
  test/          Backend tests

docs/            Operations runbook and resilience notes
android/         Android app shell, permissions, Health Connect, widgets
assets/          Icons, images, avatars, paywall assets
test/            Flutter unit/widget tests
security-tests/  Firestore rules tests
firestore.rules  Firestore security rules
storage.rules    Firebase Storage rules
```

---

## Getting started

### Prerequisites

- Flutter stable
- Dart SDK matching the Flutter version
- Node.js 18+
- Firebase project
- Android device or emulator
- RevenueCat project if testing subscriptions

### Install app dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

For Android:

```bash
flutter run -d android
```

### Generate code

Riverpod/Hive generated files are committed, but when models/providers change:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Backend setup

```bash
cd backend
npm install
npm start
```

The backend is the safe gateway for AI providers and subscription/webhook operations. Do not put private AI keys directly in the mobile app.

### Deployment

The production backend runs on Google Cloud Run and scales down to zero when
idle to keep costs low. The app finds the server through the Firebase Remote
Config key `backend_proxy_url`, so the server can be moved without an app
update. An older Render server is kept alive only for users on older app
versions.

- Deploy, validate, and roll back: [`backend/CLOUD_RUN.md`](backend/CLOUD_RUN.md)
- Day-to-day operations: [`docs/operations_runbook.md`](docs/operations_runbook.md)

### Important environment variables

| Variable | Required | Purpose |
| --- | --- | --- |
| `REQUIRE_APP_CHECK` | Yes in production | Refuses production boot when App Check is disabled. |
| `ALLOWED_ORIGINS` | Recommended | Browser origin allow-list. Native apps are not affected. |
| `REVENUECAT_WEBHOOK_AUTH` | Yes | Shared secret for RevenueCat webhooks. |
| `FIREBASE_SERVICE_ACCOUNT` | One of two | Firebase Admin service-account JSON. |
| `GOOGLE_APPLICATION_CREDENTIALS` | One of two | Path to Google application credentials. |
| `DEEPSEEK_API_KEY` | At least one AI key | Default AI provider for scans and coach. |
| `GEMINI_API_KEYS` | Optional fallback | Gemini API keys, used if listed in the provider order. |
| `OPENROUTER_API_KEY` | Optional fallback | AI fallback provider. |
| `QWEN_API_KEY` | Optional fallback | AI fallback provider. |
| `GROQ_API_KEY` | Optional fallback | AI fallback provider. |
| `AI_IMAGE_PROVIDER_ORDER` | Optional | Comma-separated provider order for photo scans. Default is `deepseek`. |
| `AI_TEXT_PROVIDER_ORDER` | Optional | Comma-separated provider order for text and coach. Default is `deepseek`. |
| `FREE_MONTHLY_SCANS` | Optional | Free monthly photo-and-voice scan limit. Default is `15`. |
| `FREE_DAILY_AI_REQUESTS` | Optional | Free daily AI request limit. Default is `30`. |
| `FREE_DAILY_AI_MESSAGES` | Optional | Free daily coach messages. Default is `1`. |
| `PRO_DAILY_SCANS` | Optional | Pro daily fair-use scan limit. Default is `100`. |
| `PRO_DAILY_AI_REQUESTS` | Optional | Pro daily fair-use AI request limit. Default is `200`. |
| `SCAN_PIPELINE` | Optional | `v1` or `v2` scan pipeline. |
| `PORT` | Optional | Backend port. |
| `API_RATE_LIMIT` | Optional | General API rate limiting. |
| `SCAN_RATE_LIMIT` | Optional | Scan-specific rate limiting. |
| `WEBHOOK_RATE_LIMIT` | Optional | Webhook rate limiting. |

---

## Testing

Run Flutter tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

Run backend tests:

```bash
cd backend
npm test
```

Run Firestore security rules tests:

```bash
cd security-tests
npm install
npm test
```

The security test command starts the Firestore and Storage emulators itself;
the Firebase CLI requires Java 21 or newer.

---

## Security model

Wazn is designed so sensitive decisions happen on the server, not on the client.

- The client never decides whether a user is Pro.
- RevenueCat webhooks and backend admin logic write subscription state.
- Firestore rules reject client writes to subscription and usage documents.
- AI provider keys stay on the backend.
- App Check protects backend requests.
- Local user data is scoped and encrypted where appropriate.
- Sign-out/account deletion paths clean local user-scoped data.

When adding synced model fields, update:

1. The Dart model
2. Firestore serialization
3. `firestore.rules`
4. `security-tests/firestore.rules.test.js`

That keeps app data and rules in sync.

---

## Camera and scanning

Wazn uses an inline custom camera experience built on Flutter’s `camera` package.

Current scan flow:

- `/snap` opens the inline camera
- camera preview is rendered inside Wazn UI
- users can capture food, choose gallery, switch to barcode, or add manually
- users can choose Voice Log, speak for up to 30 seconds, and correct the transcript before analysis
- captured image is compressed before upload
- photo and voice results open in the same review screen
- saved meals are written into the food log

Barcode scanning uses `mobile_scanner` and product lookup via OpenFoodFacts.
Voice Log sends only the reviewed transcript to `/v1/text-scan`; Wazn does not
record or upload an audio file. It uses the same monthly AI scan allowance as a
photo scan. The release entry point is controlled by the Firebase Remote Config
boolean `voice_logging_enabled`, whose safe default is `false`.

### Regional Quick Add

The Food Log can rank familiar meals without an AI request or GPS permission.
It starts with recent and frequently logged meals, then uses the saved Food
Region, planner cuisine preference, device country, current meal time, and an
international fallback. Catalogue items reuse stable nutrition IDs and per-100 g
values from `backend/data/nutrition_db.json`; each logged meal keeps a nutrition
snapshot, so later catalogue updates cannot rewrite history.

The initial offline catalogue covers common South Asian, Middle Eastern, East
Asian, American, Mediterranean, and international foods. The release surface is
controlled by the Firebase Remote Config boolean `quick_foods_enabled`, whose
safe default is `false`. Debug builds expose it automatically for device and
layout testing. Food-region and favorite preferences are cleared during account
session cleanup so another user of the same phone cannot inherit them.

---

## Monetization

Wazn uses RevenueCat for subscriptions and a backend-authoritative entitlement model.

Typical Pro value:

- far higher scan and AI limits (free users get 15 scans a month)
- AI coach
- meal planning
- macro insights
- premium tracking features

Pro is not unlimited. A daily fair-use limit protects AI cost, and when a Pro
user reaches it the server answers with HTTP 429 instead of 402, because the app
shows the paywall on 402. The backend also caps how much text the AI may write
per request.

Avoid placing upgrade CTAs everywhere. Monetization should appear at high-intent moments, such as scan limits, locked advanced insights, AI coach entry, and meal planner unlock points.

---

## Useful commands

```bash
# Flutter dependencies
flutter pub get

# Analyze app
flutter analyze

# Run all Flutter tests
flutter test

# Build Android APK
flutter build apk

# Build Android App Bundle for Play Store
flutter build appbundle

# Regenerate code
dart run build_runner build --delete-conflicting-outputs

# Backend
cd backend && npm install && npm start
```

---

## Notes for future contributors

- Keep secrets out of Git.
- Do not commit Firebase service accounts or API keys.
- Keep generated security-sensitive config files ignored.
- Run analysis and tests before pushing.
- If changing subscription behavior, check backend, Firestore rules, and RevenueCat webhook flow together.
- If changing scan behavior, test camera lifecycle: open, background, resume, barcode switch, result modal, and back navigation.

---

## License

Private project. All rights reserved.
