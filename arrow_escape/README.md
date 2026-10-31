# Arrow Escape: Traffic Puzzle

A calm, minimal traffic puzzle for iOS and Android. Tap a car to drive it off
the board, but only if its road is clear. 1,500 hand-tuned levels, a daily
challenge, a city that grows as you play, arrow skins and a
collection of picture puzzles (mountain, onion, galaxy…) unlocked with stars.

Flutter · Riverpod · go_router · freezed · CustomPainter (no game engine).
Spec, architecture and decisions: [`CLAUDE.md`](CLAUDE.md).

---

## 1. Run it (no keys needed)

Requires Flutter stable (3.47+) and, for Android, an Android SDK; for iOS,
Xcode 16+ and CocoaPods.

```sh
cd arrow_escape
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart     # Android
flutter run -t lib/main_dev.dart                  # iOS
```

Without any configuration the app is fully playable: the save is local,
ads use Google's **test** units (dev flavor and debug builds), the shop
shows "store unavailable", and Firebase features are skipped.

## 2. Checks

```sh
flutter analyze && flutter test                                   # app
(cd packages/arrow_engine && dart analyze && dart test)           # engine
(cd tool && dart analyze && dart test && dart run bin/verify_levels.dart)
```

CI (`.github/workflows/arrow_escape.yml`) runs all of the above and builds
split-per-ABI release APKs of the dev flavor, failing if any APK is over
40 MB. Download them from the run's **Artifacts**.

## 3. Levels

The campaign is generated offline by the pure-Dart tool in `tool/`:

```sh
cd tool
dart run bin/generate_levels.dart          # writes ../assets/levels (~20 s), verifies
dart run bin/verify_levels.dart            # re-solves all 1500, checks the curve
dart run bin/show_level.dart 42            # print a level + solver stats
dart run bin/show_level.dart --daily 2026-10-29
```

Generation is deterministic: the same code gives byte-identical packs.
The daily challenge is generated on device from the date and is identical
for every player (golden tests guard this; bump `DailyChallenge.version`
for intentional changes).

## 4. Production setup

Secrets never go in source. Everything below is git-ignored or passed at
build time.

### 4.1 Firebase (auth, cloud save, analytics, remote config, crashlytics)

See [`firebase/README.md`](firebase/README.md). In short: add
`android/app/src/{dev,prod}/google-services.json` and
`ios/Runner/GoogleService-Info.plist`, enable Anonymous auth, Firestore,
Remote Config, Analytics, Crashlytics, deploy `firebase/firestore.rules`,
and register App Check (Play Integrity / App Attest) with enforcement on.
The Google Services and Crashlytics Gradle plugins are applied
automatically when the json file exists.

#### Analytics

All events go through `AnalyticsService` (`lib/core/services/analytics.dart`),
one typed method per event; `docs/growth_plan.html` has the full plan.

| Area | Events | Key parameters |
| --- | --- | --- |
| Levels | `level_start`, `level_complete`, `level_fail`, `level_quit`, `level_continue` | level, mode, tier, attempt, arrows, predicted_difficulty, seconds, stars, mistakes, progress_pct, hints, paths_used, first_try |
| Help | `help_used` | type (hint/paths), level, source |
| Onboarding | `tutorial_begin`, `tutorial_step`, `tutorial_skip`, `tutorial_complete`, `tip_shown` | step, tip |
| Economy | `earn_virtual_currency`, `spend_virtual_currency`, `daily_reward_claim`, `skin_unlock`, `city_block_built`, `streak_update` | value, reason / item_name, source |
| Ads | `ad_show`, `ad_reward`, `ad_fail`, `ad_impression` (AdMob paid event → revenue) | format, placement, value, currency, ad_source |
| Store | `purchase_success`, `purchase_fail` | product, error |
| Other | `settings_change`, `save_tamper` | setting, value |

User properties (bucketed, set only on change): `max_level`, `total_stars`,
`is_payer`, `no_ads`, `streak_days`, `skin`, `a11y_mode`.

Setup in the Firebase console:

1. Register the custom dimensions you want to filter by (event-scoped:
   `level`, `tier`, `attempt`, `reason`, `placement`; user-scoped: the
   properties above).
2. Mark `level_complete` and `purchase_success` as key events.
3. Link BigQuery (Project settings → Integrations → BigQuery, daily
   export, plus streaming if you need same-day data). Level funnels,
   per-level fail/quit rates (difficulty spikes) and ARPDAU are easiest
   there, e.g. fail rate per level:
   ```sql
   SELECT (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'level') AS level,
          COUNTIF(event_name = 'level_fail') / COUNTIF(event_name = 'level_start') AS fail_rate
   FROM `PROJECT.analytics_XXXX.events_*`
   WHERE event_name IN ('level_start', 'level_fail')
   GROUP BY level ORDER BY SAFE_CAST(level AS INT64);
   ```
4. Link AdMob to Firebase so `ad_impression` revenue shows in the revenue
   reports.

Privacy: Settings → "Share usage analytics" turns collection off.
Consent mode v2 defaults (`AndroidManifest.xml`, `Info.plist`) deny ad
storage, ad user data and ad personalisation until the UMP answer arrives;
analytics storage is granted. No personal data is ever sent.

### 4.2 AdMob + mediation

1. Create the app in AdMob (one per platform) with three units: adaptive
   banner (map screen), interstitial, rewarded.
2. App ids:
   - Android: `ADMOB_APP_ID_ANDROID=ca-app-pub-…~…` in
     `android/key.properties` (or the environment).
   - iOS: `ADMOB_APP_ID = ca-app-pub-…~…` in `ios/Flutter/Secrets.xcconfig`.
3. Unit ids are `--dart-define`s read by `scripts/build_release.sh`:
   `ADMOB_ANDROID_BANNER`, `ADMOB_ANDROID_INTERSTITIAL`,
   `ADMOB_ANDROID_REWARDED`, `ADMOB_IOS_BANNER`, `ADMOB_IOS_INTERSTITIAL`,
   `ADMOB_IOS_REWARDED`. A prod release build without them ships with ads
   **off** (never with test ads).
4. Mediation: the AppLovin, Unity, Meta and ironSource/LevelPlay adapters
   are linked (`gma_mediation_*`). Add each network in AdMob → Mediation
   with its own keys. Consent reaches them through Google's certified CMP.
5. Privacy & messaging: publish a GDPR message (UMP) and, for iOS, an IDFA
   explainer. The app shows the form on first launch, then ATT on iOS, and
   offers **Settings → Privacy options** where required.
6. Ads are tagged not child-directed (the app is rated for everyone, but
   not directed at children).
7. Interstitial frequency (Remote Config): `interstitial_min_level` (10),
   `interstitial_level_gap` (3), `interstitial_min_seconds` (180).
   Interstitials only follow a finished campaign level, never precede one.

### 4.3 RevenueCat + store products

1. Create products in Play Console and App Store Connect:

   | id | type | price |
   |---|---|---|
   | `remove_ads` | non-consumable | $3.99 |
   | `starter_bundle` | non-consumable | $4.99 (no ads + 1,500 coins + Neon skin) |
   | `coins_500` / `coins_1500` / `coins_5000` | consumable | $0.99 / $2.99 / $7.99 |

2. In RevenueCat: add both apps, import the products, create entitlements
   `no_ads` (← `remove_ads`) and `starter` (← `starter_bundle`), and put all
   five in the **current** offering.
3. Pass the public SDK keys: `REVENUECAT_ANDROID_KEY`, `REVENUECAT_IOS_KEY`.

Entitlements are always read from RevenueCat (cached by its SDK offline),
never from a local flag. Bundle perks are recorded in the save so a restore
on a new device doesn't grant them twice.

### 4.4 Android release signing

```sh
keytool -genkey -v -keystore ~/arrow-escape-upload.jks -keyalg RSA \
  -keysize 4096 -validity 10000 -alias upload
```

`android/key.properties` (git-ignored):

```properties
ANDROID_KEYSTORE_PATH=/absolute/path/arrow-escape-upload.jks
ANDROID_KEYSTORE_PASSWORD=…
ANDROID_KEY_ALIAS=upload
ANDROID_KEY_PASSWORD=…
ADMOB_APP_ID_ANDROID=ca-app-pub-…~…
```

Use Play App Signing. Release builds run R8 with resource shrinking
(`android/app/proguard-rules.pro`).

### 4.5 iOS

1. Open `ios/Runner.xcworkspace`, set the bundle id
   (`com.arrowescape.arrowEscape`), team and signing.
2. Capabilities: **In-App Purchase**; **App Attest** (for App Check).
3. `pod install` runs automatically on `flutter build ios`.
4. Optional flavor schemes: duplicate the Debug/Release configurations as
   `Debug-dev`/`Release-dev`/`Debug-prod`/`Release-prod` and create `dev`
   and `prod` schemes; then `--flavor` works on iOS too. Without them, the
   entry points (`lib/main_dev.dart` / `lib/main_prod.dart`) select the
   flavor.
5. `Info.plist` already contains the ATT usage string, the AdMob app id
   (from `ADMOB_APP_ID`) and SKAdNetwork ids for Google and the mediated
   networks; refresh that list when adding networks.

### 4.6 Building releases

```sh
cp .env.example .env    # fill in ids/keys (git-ignored)
scripts/build_release.sh android   # → build/app/outputs/bundle/prodRelease/*.aab
scripts/build_release.sh apk       # split-per-ABI APKs
scripts/build_release.sh ios       # → build/ios/ipa/*.ipa
```

Builds are `--obfuscate --split-debug-info=build/symbols/<platform>`; upload
those symbols to Crashlytics to read stack traces.

## 5. Security notes

- Local save: AES-encrypted Hive box; the box key and an HMAC key are
  random per install and stored in Keychain / Android Keystore
  (`flutter_secure_storage`). An edited save fails the HMAC and loses its
  coins and coin-bought skins (progress is kept); a `save_tamper` event is
  logged. Android backup of the encrypted file is disabled; the cloud save
  is the backup.
- Firestore: each player can read and write only `users/{uid}`, and only a
  small `save` map.
- App Check gates Firestore in production.
- No secrets in the repository; real ids/keys come from git-ignored files
  or `--dart-define`.

## 6. Store listing

Copy for the stores is in [`docs/store_listing.md`](docs/store_listing.md);
a privacy policy template is in [`docs/privacy_policy.md`](docs/privacy_policy.md).
