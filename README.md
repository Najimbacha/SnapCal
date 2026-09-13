<p align="center">
  <img src="assets/icon/icon.png" alt="SnapCal app icon" width="96" height="96" />
</p>

<h1 align="center">SnapCal</h1>

<p align="center">
  AI-powered calorie tracking for people who want to log food without typing every ingredient.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-Android--first-19B98A?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Cloud%20Sync-FFCA28?style=for-the-badge&logo=firebase&logoColor=111111" />
  <img alt="RevenueCat" src="https://img.shields.io/badge/RevenueCat-Pro%20Subscriptions-6E56CF?style=for-the-badge" />
</p>

SnapCal lets users snap a meal, get an AI nutrition estimate, review detected foods, and save calories/macros into a daily food log. The app also includes barcode scanning, meal planning, hydration/activity tracking, an AI nutrition coach, subscriptions, reminders, and secure cloud sync.

> Android is the primary target right now. iOS support exists in the codebase, but current product work is Android-first.

---

## At a glance

| Product | Engineering |
| --- | --- |
| AI food scan from camera | Flutter + Riverpod mobile app |
| Barcode lookup for packaged food | Node.js / Express backend |
| Daily calorie, macro, hydration, and activity tracking | Firebase Auth, Firestore, Storage, FCM, App Check |
| AI coach and meal planning | Backend-proxied AI providers |
| Pro subscription experience | RevenueCat + server-authoritative entitlements |

---

## What SnapCal does

- Camera-based AI food scanning
- Barcode lookup for packaged food
- Daily calories, macros, meals, hydration, activity, and weight tracking
- AI nutrition coach for meal and goal guidance
- Meal planner with grocery-style planning support
- Food log with scanned and manually added meals
- Health Connect activity integration on Android
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
Choose food scan or barcode
  ↓
Scan meal
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
| Local storage | Hive + secure storage |
| Camera | `camera`, `image_picker`, `mobile_scanner` |
| Charts/UI | `fl_chart`, `flutter_animate`, `lucide_icons`, Material |
| Backend | Node.js / Express |
| AI | Backend-proxied AI providers, Gemini-first |
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
  planner/       Meal-planning and nutrition conversion logic
  providers/     Riverpod app state
  screens/       App screens and feature UI
  widgets/       Shared UI components

backend/
  server.js      Express API for scans, entitlements, webhooks, admin tools
  services/      Nutrition DB provider, reminders, backend helpers
  cron/          Scheduled jobs

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

### Important environment variables

| Variable | Required | Purpose |
| --- | --- | --- |
| `REQUIRE_APP_CHECK` | Yes in production | Refuses production boot when App Check is disabled. |
| `ALLOWED_ORIGINS` | Recommended | Browser origin allow-list. Native apps are not affected. |
| `REVENUECAT_WEBHOOK_AUTH` | Yes | Shared secret for RevenueCat webhooks. |
| `FIREBASE_SERVICE_ACCOUNT` | One of two | Firebase Admin service-account JSON. |
| `GOOGLE_APPLICATION_CREDENTIALS` | One of two | Path to Google application credentials. |
| `GEMINI_API_KEYS` | At least one AI key | Gemini API keys for AI scan/coach features. |
| `DEEPSEEK_API_KEY` | Optional fallback | AI fallback provider. |
| `OPENROUTER_API_KEY` | Optional fallback | AI fallback provider. |
| `QWEN_API_KEY` | Optional fallback | AI fallback provider. |
| `GROQ_API_KEY` | Optional fallback | AI fallback provider. |
| `FREE_MONTHLY_SCANS` | Optional | Free monthly scan limit. Default is `3`. |
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

---

## Security model

SnapCal is designed so sensitive decisions happen on the server, not on the client.

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

SnapCal uses an inline custom camera experience built on Flutter’s `camera` package.

Current scan flow:

- `/snap` opens the inline camera
- camera preview is rendered inside SnapCal UI
- users can capture food, choose gallery, switch to barcode, or add manually
- captured image is compressed before upload
- AI scan result opens in the review screen
- saved meals are written into the food log

Barcode scanning uses `mobile_scanner` and product lookup via OpenFoodFacts.

---

## Monetization

SnapCal uses RevenueCat for subscriptions and a backend-authoritative entitlement model.

Typical Pro value:

- higher or unlimited scan limits
- AI coach
- meal planning
- macro insights
- premium tracking features

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
