# Commits the entitlement fixes + paywall redesign and tags the release.
# Run from the repo root:  .\_commit_release.ps1

$ErrorActionPreference = "Stop"
$tag = "v1.0.22+38"          # matches pubspec.yaml (version: 1.0.22+38)

Write-Host "`n=== 1. Verifying the build first ===" -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nanalyze failed - nothing committed. Fix, then re-run." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== 2. Removing Claude's scratch folder ===" -ForegroundColor Cyan
# Holds the deleted subscription_provider files, two stale git index locks and
# the transfer archives. The device bridge cannot delete files, so it was left
# for you.
if (Test-Path "_to_delete") { Remove-Item -Recurse -Force "_to_delete" }

Write-Host "`n=== 3. Staging ===" -ForegroundColor Cyan
git add -A
git status --short

Write-Host "`n=== 4. Committing ===" -ForegroundColor Cyan
$msg = @'
fix(pro): stop revoking Pro from paying users, and rebuild the paywall

Pro status had four writers and two readers that were not connected to
each other, so a paying user could be shown the upgrade wall in several
independent ways. Twenty findings from a full audit of lib/ and the
subscription paths in backend/server.js.

Entitlement chain
- SettingsRepository (and the meal/water/assistant repositories) are now
  singletons. Each instance owned its own broadcast StreamController, so
  SubscriptionService wrote Pro status into the AppInitializer instance
  while settingsProvider watched a different one -- a completed purchase
  updated Hive but never reached the UI until the app was relaunched.
- The RevenueCat webhook no longer treats CANCELLATION, BILLING_ISSUE or
  PRODUCT_CHANGE as revocations. Turning off auto-renew, hitting a billing
  grace period or switching plans used to kill access instantly even
  though the period was paid for. Expiry decides now, not the event name.
- The client never downgrades on a negative or failed backend read.
  _hasProAccess is wired up at last, so a late or misconfigured webhook
  cannot strip Pro from a device holding a live store entitlement.
  getPremiumStatus() gains a throttled RevenueCat REST fallback.
- syncFromFirestore no longer reads "subscription doc missing" as "not
  subscribed", and a transient null from authStateChanges is debounced
  instead of wiping Pro and logging out of RevenueCat.
- New three-state proAccessProvider (unknown | free | pro). Every gate and
  every upsell now reads one source; "still loading" is no longer answered
  as "free", which is what put "Unlock SnapCal Pro" in front of paying
  users on cold start and just after a purchase.

Gates that were not gating
- The AI coach was ungated: CoachLockedOverlay was imported nowhere and
  the counters in PremiumGateService were never called. Enforced on the
  client and independently in /api/ai/text (coach requests only, so the
  planner and reports are unaffected).
- The promotional paywall never ran -- canShowPromotionalPaywall had no
  caller. Wired up, including the dismissal cooldown that was written but
  never read.

Data loss on cloud sync
- Settings merge field-by-field instead of wholesale replacement; nine
  fields including medicalNotes and foodDislikes were being reset to
  defaults on every sign-in.
- Numeric JSON widens through num: a whole-number height from Firestore
  threw a TypeError that silently aborted the entire settings sync.
- startingWeight is written under its own key rather than as `weight`.

Paywall
- Full redesign around the food photography: a scan sequence over the
  plate, a hairline benefit ledger, the trial as a three-point rail, plan
  cards and a pinned CTA dock carrying the billing disclosure. Reuses the
  existing l10n keys across all four languages; every purchase, restore
  and offerings path is preserved.

Also: streak recomputes from real meals rather than inventing a logged
day, scan quota migrates across the anonymous-to-Google UID switch,
prompt cooldowns wait for auth before choosing a pref scope, and the
ref.watch calls inside async callbacks are ref.read.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_013zxa8TEwGevbs1QijCn8LG
'@

$msg | git commit -F -

Write-Host "`n=== 5. Tagging $tag ===" -ForegroundColor Cyan
git tag -a $tag -m "Pro entitlement fixes and paywall redesign"

Write-Host "`nDone. Review with:" -ForegroundColor Green
Write-Host "  git show --stat HEAD"
Write-Host "`nThen push when you are happy:" -ForegroundColor Green
Write-Host "  git push origin fix/audit-remediation"
Write-Host "  git push origin $tag"
