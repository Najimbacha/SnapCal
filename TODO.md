# TODO

## Firebase console (device log, 2026-08-25)

- [ ] Enable the App Check API for project `183409999145`:
      https://console.developers.google.com/apis/api/firebaseappcheck.googleapis.com/overview?project=183409999145
- [ ] Register the debug App Check token (`27c2642d-6e51-4f17-9be9-10358b549f06`)
      in Firebase Console → App Check → Apps → Android → Manage debug tokens.
- [ ] Register the debug keystore SHA-1/SHA-256 in Project Settings → Android app
      (clears the `DEVELOPER_ERROR` / GoogleApiManager SecurityException in logcat):
      `keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android`

## Result screen (snap result modal)

- [ ] UI polish pass on `lib/screens/snap/widgets/result_modal.dart` — same
      treatment the paywall/log/hydration screens got: type scale, 4pt rhythm,
      color restraint, consistency with the warm light design language.
