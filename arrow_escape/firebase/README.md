# Firebase setup

1. Create a Firebase project with an Android app (`com.riseivo.arrow.escape.game`,
   plus `com.riseivo.arrow.escape.game.dev` for the dev flavor) and an iOS app.
2. Download the config files (they are git-ignored):
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
