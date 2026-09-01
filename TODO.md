# TODO

## Firebase console (device log, 2026-08-29)

- [ ] Register the debug App Check token (`7f80bd1f-16b7-499b-92a7-55271fc32c5c`)
      in Firebase Console → App Check → Apps → Android → Manage debug tokens
      (link: https://console.firebase.google.com/project/snapcal-ef333/appcheck/apps?selectedAppId=1:183409999145:android:abef6ba24a0ebaad644b38).
      This unblocks scanning in debug builds against the production backend.
- [ ] Production: enable App Check API for project `183409999145`:
      https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview?project=183409999145
- [ ] Production: register Play Integrity provider for the Android app in
      Firebase Console → App Check → Apps, and add the **Play App Signing key
      SHA-256** (from Google Play Console → App integrity) to Project Settings
      → Android app fingerprints. Without it, Play-installed release builds
      will keep failing App Check.
- [ ] Firestore: the device log shows `PERMISSION_DENIED` on
      `users/{uid}`, `users/{uid}/meals`, `users/{uid}/private/profile`,
      `users/{uid}/subscription/current`, `users/{uid}/settings/app`.
      Review firestore.rules to allow the app's authenticated reads.

## Result screen (snap result modal)

- [ ] UI polish pass on `lib/screens/snap/widgets/result_modal.dart` — same
      treatment the paywall/log/hydration screens got: type scale, 4pt rhythm,
      color restraint, consistency with the warm light design language.
