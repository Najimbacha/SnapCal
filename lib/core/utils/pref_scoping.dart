/// Helpers for user-scoping SharedPreferences keys.
///
/// Every rate-limit / usage / prompt-state key must be namespaced by the
/// signed-in UID so account switching on a shared device cannot inherit the
/// previous user's scan quota, AI-message budget, paywall cooldowns or
/// review-prompt state. When no user is resolvable (pre-auth, or unit tests
/// where Firebase is not initialised) the bare key is used unchanged, which
/// keeps existing behaviour and tests intact.
library;

import 'package:firebase_auth/firebase_auth.dart';

/// Returns the current Firebase UID, or null when auth is unavailable.
String? resolvePrefScope() {
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    return null;
  }
}

/// Namespaces [base] with the current UID. Falls back to the bare key when no
/// scope is resolvable.
String scopedPrefKey(String base) {
  final scope = resolvePrefScope();
  if (scope == null || scope.isEmpty) return base;
  return '$scope:$base';
}

/// Whether [key] is [base] or a scoped variant of it (any UID).
bool prefKeyBelongsTo(String key, String base) {
  return key == base || key.endsWith(':$base');
}

/// UTC day key (`YYYY-MM-DD`). Quota and daily counters use UTC so a device
/// clock change or timezone crossing cannot reset or double-count them, and
/// they stay consistent with the server's UTC month windows.
String utcDateKey(DateTime date) {
  return '${date.toUtc().year.toString().padLeft(4, '0')}-'
      '${date.toUtc().month.toString().padLeft(2, '0')}-'
      '${date.toUtc().day.toString().padLeft(2, '0')}';
}

/// UTC month key (`YYYY-MM`), matching backend `currentMonthKey()`.
String utcMonthKey(DateTime date) {
  final u = date.toUtc();
  return '${u.year.toString().padLeft(4, '0')}-${u.month.toString().padLeft(2, '0')}';
}
