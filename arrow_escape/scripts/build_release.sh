#!/usr/bin/env bash
# Builds store-ready release binaries for the prod flavor.
#
#   scripts/build_release.sh android   # app bundle for Play
#   scripts/build_release.sh ios       # IPA for App Store Connect
#
# Real ad unit ids and RevenueCat keys come from the environment (or a
# git-ignored .env file), never from source:
#   ADMOB_ANDROID_BANNER ADMOB_ANDROID_INTERSTITIAL ADMOB_ANDROID_REWARDED
#   ADMOB_IOS_BANNER ADMOB_IOS_INTERSTITIAL ADMOB_IOS_REWARDED
#   REVENUECAT_ANDROID_KEY REVENUECAT_IOS_KEY
# Android signing: android/key.properties (see README).
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -f .env ]]; then set -a; source .env; set +a; fi

platform="${1:-android}"
symbols="build/symbols/$platform"
defines=()
for name in ADMOB_ANDROID_BANNER ADMOB_ANDROID_INTERSTITIAL ADMOB_ANDROID_REWARDED \
            ADMOB_IOS_BANNER ADMOB_IOS_INTERSTITIAL ADMOB_IOS_REWARDED \
            REVENUECAT_ANDROID_KEY REVENUECAT_IOS_KEY; do
  if [[ -n "${!name:-}" ]]; then
    defines+=("--dart-define=$name=${!name}")
  else
    echo "warning: $name is not set; that feature stays off in this build" >&2
  fi
done

common=(--release -t lib/main_prod.dart
        --obfuscate --split-debug-info="$symbols" "${defines[@]}")

case "$platform" in
  android) flutter build appbundle --flavor prod "${common[@]}" ;;
  apk)     flutter build apk --flavor prod --split-per-abi "${common[@]}" ;;
  # iOS flavors need Xcode schemes (README); the prod entry point is enough.
  ios)     flutter build ipa "${common[@]}" ;;
  *) echo "usage: $0 android|apk|ios" >&2; exit 64 ;;
esac

echo "Debug symbols for de-obfuscating crashes: $symbols"
echo "Upload them to Crashlytics: firebase crashlytics:symbols:upload --app=<APP_ID> $symbols"
