# Arrow Escape: Traffic Puzzle — project spec & conventions

Production Flutter game for iOS + Android. This file is the source of truth for
scope, rules and conventions. Update it when a decision changes.

## Toolchain

- Flutter stable (3.47.x), Dart 3.13. Run commands from `arrow_escape/`.
- Checks that must pass before every commit / at the end of every phase:
  ```sh
  flutter analyze
  flutter test
  (cd packages/arrow_engine && dart analyze && dart test)
  ```
- Codegen (freezed / json_serializable):
  `dart run build_runner build --delete-conflicting-outputs`. Generated
  `*.freezed.dart` / `*.g.dart` files are committed.

## Core game

- A board is a grid of arrows (cars). Tapping a car slides it out in its
  direction if the path to the board edge is clear. If blocked it bumps toward
  the blocker and back, and the player loses a heart (3 hearts per level).
  0 hearts = level failed.
- Multi-segment vehicles (trucks) move like a snake: the body follows the head,
  so only the head's ray to the edge matters.
- Rendering uses `CustomPainter` (no Flame). 60fps animations driven by a
  single `Ticker`, haptics, soft sounds.
- Pinch-zoom + pan (`InteractiveViewer`), "show paths" toggle, 1 free undo per
  level (reverts the last exit; hearts are not refunded), large tap targets
  (nearest-piece hit test with tolerance), double-tap protection (a piece that
  is already animating ignores taps; per-piece debounce).
- Mechanics unlock gradually:
  - **L20 trucks** — multi-segment vehicles (straight or bent, 2–4 cells).
  - **L40 traffic lights** — a light sits on an empty cell; every successful
    exit toggles all lights. A red light blocks any path that crosses it.
  - **L70 one-way gates** — a gate on an empty cell forces traffic entering
    it to turn and continue in the gate's direction (paths can bend).
    Entering against the arrow is impossible (the vehicle bumps), and gate
    loops never exit. (A gate that merely blocks would be static: a car
    either could never leave or the gate would not matter.)
  - **L100 ambulance** — while the ambulance is on the board, the only other
    vehicles allowed to move are the ones standing in its lane (on its exit
    ray). Moving anything else costs a heart ("Let the ambulance through!").
- Stars per level: 3 = no hearts lost, 2 = one lost, 1 = two lost.

## Levels

- `tool/` is a Dart CLI package: seeded procedural generator + solver.
  Generation is by reverse placement (each newly placed piece must be able to
  exit given the pieces already placed), so every level is solvable by
  construction; the solver then verifies each level and scores difficulty
  (min moves, branching factor, blocker depth).
- Boards use shape masks (car, animals, hearts, letters, landmarks), not just
  rectangles.
- 1500 pre-generated levels shipped as compressed (gzip) JSON assets with a
  smooth difficulty curve and a "breather" (easier) level every 5th level.
- Daily challenge generated on-device from a date seed (same generator, shared
  via the pure-Dart `arrow_engine` package).

## Meta / retention

- City map: every 10 levels builds a city block.
- Vehicle skins unlockable with coins. Daily streak, daily reward, star rating.

## UI

- Clean, minimal, rounded, soft pastel palette. Light/dark mode. Thick-arrow,
  high-contrast and colorblind (shape/pattern + Okabe-Ito palette) modes.
- Material 3 with a custom theme. Google Font (Nunito, OFL) bundled as TTF
  assets declared in `pubspec.yaml` — never fetched at runtime, so the
  `google_fonts` package isn't needed.
- Screens: splash, home, level map, game, win/lose, shop, skins, settings,
  daily challenge.
- App size under 40MB.

## Ads (behind `AdService`)

- google_mobile_ads + AdMob mediation adapters (AppLovin, Unity, Meta,
  ironSource/LevelPlay).
- Rewarded: hint, extra heart, double coins, unlock skin.
- Interstitial: none before L10, then at most 1 per 3 levels AND 3 minutes
  (values from Firebase Remote Config). Never before a level starts.
- Banner only on the map screen.
- Google UMP consent (GDPR) + iOS ATT prompt. Test ad IDs in debug; real IDs
  come from flavors / `--dart-define`, never hardcoded. Ads not child-directed.

## In-app purchases (behind `PurchaseService`)

- RevenueCat (`purchases_flutter`). Products: `remove_ads` (non-consumable,
  $3.99, removes interstitials + banner), coin packs (consumable), starter
  bundle. Restore purchases button. Entitlements checked via RevenueCat, not
  local flags.

## Backend

- Firebase: anonymous auth, Firestore cloud save (synced with local save),
  Remote Config, Analytics (`level_start`, `level_complete`, `level_fail`, ad
  and purchase events), Crashlytics.

## Security

- Firebase App Check (Play Integrity / App Attest). Firestore rules: a user can
  read/write only their own doc.
- Local save in Hive, encrypted with a key stored in `flutter_secure_storage`.
  Coins/progress carry an HMAC to detect tampering.
- No secrets in code. Release builds use `--obfuscate --split-debug-info`,
  R8/ProGuard enabled.

## Architecture

- Riverpod (state), go_router (navigation), feature-first folders, freezed
  models for app/UI state and persisted data.
- The game engine (`packages/arrow_engine`) is pure Dart with zero
  dependencies so the CLI tool, the app and the tests share it. Its hot-path
  types (board state, pieces) are hand-written immutable classes rather than
  freezed, because the solver creates millions of them.
- Unit tests for the engine, generator and solver; widget tests for key
  screens. Flavors: `dev` / `prod` (`lib/main_dev.dart`, `lib/main_prod.dart`,
  Android productFlavors, iOS schemes).

### Folder structure

```
arrow_escape/
├── CLAUDE.md
├── pubspec.yaml
├── assets/
│   ├── fonts/            Nunito (bundled Google Font)
│   ├── sounds/           soft UI sounds (tiny WAVs)
│   └── levels/           levels_XXXX.json.gz (phase 2)
├── packages/
│   └── arrow_engine/     pure Dart: geometry, level model, rules, solver,
│       ├── lib/src/      generator, shape masks, difficulty scoring
│       └── test/
├── tool/                 Dart CLI package: generate / verify levels
├── lib/
│   ├── main.dart         default entry (dev)
│   ├── main_dev.dart / main_prod.dart
│   ├── app/              app widget, router, flavor config, bootstrap
│   ├── core/
│   │   ├── theme/        palette, ThemeData, accessibility variants
│   │   ├── services/     haptics, sound, (ads, purchases, analytics…)
│   │   └── widgets/      shared UI pieces
│   └── features/
│       ├── splash/
│       ├── home/
│       ├── game/         application/ (controller, state) + presentation/
│       ├── settings/
│       ├── level_map/    (phase 3)  city/  shop/  skins/  daily/
│       └── …
├── test/                 widget tests + app-level unit tests
├── android/  ios/
```

## Status / decisions log

- Phase 1 done: engine (`packages/arrow_engine`), theme, game screen,
  splash/home/settings, Android `dev`/`prod` productFlavors. Settings and
  progress are in-memory until phase 3 adds the encrypted Hive store.
- Hand-made sample levels (`samples.dart`) stand in for the campaign until
  phase 2's generated packs.
- The engine has a basic DFS solver already (used for tests and hints);
  phase 2 adds difficulty scoring.
- iOS schemes for flavors need Xcode and are set up in phase 7.
- Double-tap protection: a vehicle that is bumping/returning ignores taps,
  repeat taps on one vehicle within 280 ms count once, and taps on the cell
  of a vehicle that is driving away are swallowed (so the tap tolerance
  can't hand them to a neighbour).

## Phases

1. Scaffold + theme + core engine + game screen
2. Generator/solver tool + 1500 levels + daily challenge
3. Meta: map, city, skins, coins, streak
4. Ads + consent
5. IAP
6. Firebase: cloud save, analytics, remote config, crashlytics
7. Security + release configs (Android signing, iOS setup)
8. Polish, accessibility, performance pass, store listing text + README

After each phase: `flutter analyze` + tests, fix everything, review for bugs,
then stop and summarize.

## Conventions

- `package:` imports only; no relative imports across features.
- No secrets, ad unit IDs or API keys in source. Use `--dart-define` /
  flavor config.
- Services that touch platform plugins sit behind an interface and get a no-op
  / fake implementation in tests.
- Keep engine code free of Flutter imports.
