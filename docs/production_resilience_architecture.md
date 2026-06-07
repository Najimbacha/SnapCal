# Production Resilience Architecture

This app should treat every remote, storage, payment, camera, and AI operation as unreliable. The baseline contract is:

- every async operation has a timeout;
- retry is explicit and bounded;
- duplicate operations are gated by operation key;
- providers expose `AsyncUiState`;
- stale cached data is preferred over a blank or frozen screen;
- failures are converted to `AppFailure` before reaching UI;
- UI has loading, refreshing, empty, error, offline, partial, and retry states.

## Core Primitives

- `AppFailure`: canonical failure model for Dio, Firebase, platform, local storage, timeout, quota, auth, and upload failures.
- `RetryPolicy`: bounded retry policies for network, auth, AI, cloud sync, uploads, payments, and local storage.
- `SafeAsync`: runs operations with timeout, retry, cancellation checks, fallback data, and duplicate-operation gates.
- `ResilientProviderMixin.guardOperation`: provider-level wrapper that updates `AsyncUiState`, rejects duplicate taps, and ignores stale results after dispose or newer operations.
- `AsyncUiState`: screen and section state model for blocking load, background refresh, retrying, success, empty, error, offline, and partial cached states.
- `AppStateView`: reusable UI renderer for the state model.
- `SyncQueueService` and `UploadQueueService`: offline recovery queues for Firestore writes and resumable uploads.

## Provider Pattern

Providers should use `ResilientProviderMixin` and move async work through `guardOperation`.

```dart
final result = await guardOperation<List<Item>>(
  label: 'Load items',
  operationKey: 'items:load',
  operation: repository.loadItems,
  timeout: TimeoutPolicy.firestore,
  retryPolicy: RetryPolicy.cloudSync,
  fallbackData: _items,
  setState: (next) => _uiState = next,
  isEmpty: (items) => items.isEmpty,
);

if (result.isSuccess) {
  _items = result.requireData;
}
```

Use optimistic UI only when local persistence is guaranteed first. Otherwise, show a pending/refreshing state until the confirmed write returns.

## Screen Contract

Every screen should render:

- `loading`: skeleton or blocking progress for first load;
- `success`: confirmed data;
- `empty`: valid no-data state;
- `error`: non-retryable or unexpected failure;
- `offline`: no reachable network and no usable fallback;
- `partial`: cached/stale data plus a warning/retry affordance;
- `retrying/refreshing`: non-blocking progress overlay.

Do not leave a button enabled while its operation key is running.

## Scan Flow

Preferred production flow:

1. compress image locally and enforce size limit;
2. upload to Firebase Storage with content type and owner-scoped path;
3. create scan document through authenticated backend;
4. process scan through backend;
5. parse AI JSON defensively;
6. cache successful scan result by image hash;
7. if upload is interrupted, enqueue for retry or return manual input with a precise failure.

Temporary compatibility flow:

- if private upload fails because production backend/storage is not ready, fallback to legacy `/api/scan-food`;
- remove this fallback after Railway is redeployed with `/api/food-scans`.

## Payment Flow

RevenueCat purchase state is not final until server verification confirms it.

- show pending state after purchase if verification is delayed;
- retry verification with `RetryPolicy.paymentVerification`;
- never grant release-build Pro from local-only state;
- debug-only overrides must stay in memory and be guarded by `kDebugMode`.

## Offline Strategy

- local Hive is the source for immediate UI;
- Firestore writes enqueue when cloud sync fails;
- upload jobs enqueue and retry with backoff;
- stale data should be marked `partial`, not replaced with empty;
- app resume should flush due sync/upload queues.

## Migration Priority

1. Scan upload and result parsing.
2. Subscription verification and paywall purchase states.
3. Meal, water, metrics, planner providers.
4. Settings/profile/onboarding persistence.
5. Background services and Health Connect permission handling.
6. Remaining screen sections using raw loading booleans.
