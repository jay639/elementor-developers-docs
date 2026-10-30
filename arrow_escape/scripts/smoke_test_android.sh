#!/usr/bin/env bash
# Installs a release APK on a running emulator/device, launches it, and
# fails if the app process dies. Prints the crash log either way.
#   scripts/smoke_test_android.sh path/to/app.apk com.arrowescape.arrow_escape.dev
set -uo pipefail
apk="$1"
pkg="$2"

adb wait-for-device
adb logcat -c
adb install -r "$apk" || exit 1
adb shell monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 >/dev/null

alive=1
for i in $(seq 1 30); do
  sleep 1
  if ! adb shell pidof "$pkg" >/dev/null; then alive=0; break; fi
done

adb logcat -d > logcat.txt
echo "===== crash / error lines ====="
grep -E "FATAL|AndroidRuntime|E flutter|Exception|Error|libc  |DEBUG   :|ActivityManager: Process .* has died|ActivityManager: Force" logcat.txt | grep -v "GoogleApiManager\|ConnectionResult" | head -200

echo "===== app log ====="
grep -E " (I|W|E) flutter" logcat.txt | head -80

if [ "$alive" = 1 ]; then
  echo "App stayed up for 30s."
  adb exec-out screencap -p > screenshot.png
  # The UI tree proves the app got past the splash and rendered home.
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  adb pull /sdcard/ui.xml ui.xml >/dev/null 2>&1
  if grep -q "Play" ui.xml; then
    echo "Home screen rendered (found the Play button)."
    exit 0
  fi
  echo "::error::App is running but the home screen did not render"
  grep -o 'content-desc="[^"]*"\|text="[^"]*"' ui.xml | sort -u | head -40
  exit 1
fi
echo "::error::App process died after launch"
exit 1
