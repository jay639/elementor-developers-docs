# Arrow Escape: Traffic Puzzle

Flutter puzzle game for iOS and Android. Tap the cars to drive them off the
board, but only when their road is clear.

See `CLAUDE.md` for the full spec, architecture and phase plan. Full setup
steps (Firebase, AdMob, RevenueCat, signing) come in phase 8.

## Quick start

```sh
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart     # Android
flutter run -t lib/main_dev.dart                  # iOS (schemes in phase 7)
```

## Checks

```sh
flutter analyze && flutter test
(cd packages/arrow_engine && dart analyze && dart test)
(cd tool && dart analyze && dart test)
```

Regenerate freezed / json code after changing models:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Levels (pure Dart CLI in `tool/`):

```sh
cd tool
dart run bin/generate_levels.dart       # writes ../assets/levels, then verifies
dart run bin/verify_levels.dart         # re-solves and checks the campaign
dart run bin/show_level.dart 42         # print a level and its stats
dart run bin/show_level.dart --daily 2026-10-29
```

Regenerate the sound effects: `python3 tool/sounds/make_sounds.py`.
