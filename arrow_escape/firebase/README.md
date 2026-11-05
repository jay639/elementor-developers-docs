# Firebase setup

1. Create a Firebase project with an Android app (`com.riseivo.arrow.escape.game`,
   plus `com.riseivo.arrow.escape.game.dev` for the dev flavor) and an iOS app.
2. CI: add the Android `google-services.json` (one file listing both
   packages) as the repository secret `GOOGLE_SERVICES_JSON` (GitHub →
   Settings → Secrets and variables → Actions). The workflow writes it to
   `android/app/google-services.json` before building.
   Locally, download the config files (they are git-ignored):
   - `android/app/src/prod/google-services.json` and
     `android/app/src/dev/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. Enable **Authentication → Anonymous**, **Firestore**, **Remote Config**,
   **Analytics** and **Crashlytics**.
4. Deploy the rules: `cd firebase && firebase deploy --only firestore`.
5. **App Check**: register Play Integrity (Android) and App Attest (iOS),
   then turn on enforcement for Firestore. For debug builds, copy the debug
   token printed in the device log into App Check → Manage debug tokens.
6. Remote Config parameters (defaults are built into the app):
   `interstitial_min_level` (10), `interstitial_level_gap` (3),
   `interstitial_min_seconds` (180).

Without the config files the app still runs, fully offline (local save,
no analytics, default ad frequency).

## Push notifications

- Automatic reminders are local notifications scheduled on the device
  (7:30 PM local time; `ReminderPlanner`), so they need no server.
- Console pushes: Firebase → **Messaging → New campaign → Notifications**.
  Target the app (`com.riseivo.arrow.escape.game` / `.dev`) or the topic
  `all`. Optional: under *Additional options → Custom data* add the key
  `route` with `/daily`, `/collection`, `/shop` or `/map` to open that
  screen when tapped.
- Players can turn both off in Settings → Reminders.
