# SnapCal Production Resilience Playbook

This app must assume every async boundary can fail, return late, return malformed data, or complete after the user leaves the screen. The production architecture is:

1. UI widgets render `AsyncUiState`: loading, success, empty, error, offline, retrying, and partial states.
2. Providers own operation state, duplicate-tap gates, cancellation checks, and optimistic UI rollback.
3. Repositories write local-first, then sync cloud changes through `SyncQueueService`.
4. Services wrap external calls with `SafeAsync`, `TimeoutPolicy`, `RetryPolicy`, and defensive parsing.
5. App startup and lifecycle recovery flush sync queues and re-check RevenueCat entitlements on resume.

## Failure Policy

- Network or weak internet: use short connect timeouts, bounded retries with jitter, and an offline fallback.
- API timeout: never leave a spinner running; move to retryable error or cached/partial state.
- Duplicate taps: guard by operation key or provider boolean before starting the operation.
- Partial failure: keep local state and enqueue remote sync instead of rolling back user-visible work.
- Bad API response: parse with type checks, clamp numbers, and fail with `AppFailureType.badResponse`.
- Auth expiration: refresh the Firebase ID token once centrally, retry the request once, then surface sign-in recovery.
- Firestore unavailable or quota exceeded: keep Hive data, enqueue sync, and show stale/partial state if useful.
- Payment delay: do not assume purchase failed immediately; verify now and schedule delayed entitlement checks.
- App resume: flush pending sync and verify entitlement again.
- Memory pressure: release image/camera-heavy objects and avoid retaining large byte arrays after use.

## Required Pattern For New Async Work

```dart
final result = await SafeAsync.run<MyData>(
  label: 'Human readable operation name',
  operationKey: 'stable-dedup-key',
  operation: () => service.fetchData(),
  timeout: TimeoutPolicy.firestore,
  retryPolicy: RetryPolicy.cloudSync,
  fallbackData: cachedData,
  isActive: () => mountedOrProviderStillAlive,
);

if (result.isSuccess) {
  state = const AsyncUiState.success();
} else if (result.failure!.isOfflineLike && result.hasFallback) {
  state = AsyncUiState.partial(
    message: result.failure!.message,
    failure: result.failure,
  );
} else {
  state = AsyncUiState.error(result.failure!.message, result.failure);
}
```

## Screen Contract

Every screen should have:

- `loading`: first load or blocking work.
- `success`: normal data.
- `empty`: valid no-data state.
- `error`: failed operation with retry.
- `offline`: no internet and no useful cache.
- `partial`: cached/local data shown while cloud sync is pending.
- `refreshing`: non-blocking linear progress over existing content.

Prefer `AppStateView` or `AppAsyncOverlay` instead of hand-built spinners.

## Offline-First Data

For user-owned data:

1. Validate input.
2. Write to Hive immediately.
3. Update provider/UI immediately.
4. Try Firestore with timeout.
5. On failure, enqueue `SyncQueueService`.
6. Flush queue on connectivity regain and app resume.

Never block meal logging, water logging, settings edits, or progress metrics solely on Firestore.

## Optimistic UI

Use optimistic UI when the operation is local, reversible, or queued:

- grocery checkbox
- meal add/edit/delete
- settings changes
- local progress entries

Use confirmed UI when money, identity, destructive account operations, or irreversible cloud work is involved:

- purchases
- sign-in/linking
- account deletion
- restore subscription

## AI Scan Flow

Safe scan flow:

1. Gate duplicate scan requests.
2. Check connectivity with `ConnectivityService.refreshReachability(force: true)`.
3. Capture or pick image with timeout.
4. Compress image off the UI path and enforce max upload size.
5. Call AI through `SafeAsync` with retry and timeout.
6. Parse response defensively.
7. Cache successful analysis by image hash.
8. If scan fails, open manual meal entry instead of dead-ending.

## Payment Flow

RevenueCat is eventually consistent. A purchase can succeed while entitlement updates lag.

1. Start purchase with duplicate-tap disabled.
2. Process returned `CustomerInfo`.
3. If active, unlock immediately.
4. If inactive, run `verifyCurrentEntitlement`.
5. If still inactive, schedule delayed checks and show a pending/retry message.
6. Re-check on app resume.

## Testing Failure Modes

Simulate:

- airplane mode before scan, login, restore, and meal sync
- slow 2G or packet loss in Android Emulator network settings
- API 500, 401, 429, malformed JSON, and empty body
- Firebase emulator unavailable
- RevenueCat delayed `CustomerInfo`
- app backgrounded during image scan
- repeated rapid taps on primary buttons
- Hive box corruption by deleting/altering local files in debug
- low memory by using large gallery images on low-end Android profiles

## Common Ways Real Users Break Apps

- double-tap paid actions or log buttons
- leave the app while upload/scan is running
- return after auth token expiry
- switch networks mid-request
- run on devices with slow storage and small memory
- deny permissions or revoke them in system settings
- use old cached data after a cloud write fails
- purchase while the store backend is slow

Happy-path apps fail because they treat async work as a single linear success path. Production apps treat every boundary as unreliable and preserve user intent locally until the remote system catches up.
