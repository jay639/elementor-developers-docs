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
# Stream the log to disk from the start, so it survives even if the
# emulator itself goes down (a dump at the end would get nothing).
adb logcat -v threadtime > logcat.txt 2>&1 &
logcat_pid=$!
timeout 60 adb shell monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 >/dev/null

# Give a just-booted emulator time to spawn the process before judging.
started=0
for i in $(seq 1 20); do
  if timeout 10 adb shell pidof "$pkg" >/dev/null; then started=1; break; fi
  sleep 1
done
if [ "$started" = 0 ]; then
  echo "::error::App process never started"
  grep -E "$pkg|ActivityTaskManager|AndroidRuntime|FATAL" logcat.txt | tail -n 60
  exit 1
fi

alive=1
for i in $(seq 1 30); do
  sleep 1
  if ! timeout 10 adb shell pidof "$pkg" >/dev/null; then alive=0; break; fi
done
if ! timeout 10 adb shell true >/dev/null 2>&1; then
  echo "::error::The emulator stopped responding after the app launched"
  echo "===== app / graphics lines ====="
  grep -iE "arrow_escape|flutter|impeller|vulkan|EGL_emulation|FATAL|libc  " logcat.txt | tail -n 80
  echo "===== last log lines ====="
  tail -n 150 logcat.txt
  exit 1
fi
kill "$logcat_pid" 2>/dev/null || true
echo "===== crash / error lines ====="
grep -E "FATAL|AndroidRuntime|E flutter|Exception|Error|libc  |DEBUG   :|ActivityManager: Process .* has died|ActivityManager: Force" logcat.txt | grep -v "GoogleApiManager\|ConnectionResult" | head -200

echo "===== app log ====="
grep -E " (I|W|E) flutter" logcat.txt | head -80

if [ "$alive" = 1 ]; then
  echo "App stayed up for 30s."
  timeout 30 adb exec-out screencap -p > screenshot.png
  # The UI tree proves the app got past the splash and rendered home.
  timeout 60 adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  timeout 30 adb pull /sdcard/ui.xml ui.xml >/dev/null 2>&1
  if grep -q "Play" ui.xml; then
    echo "Home screen rendered (found the Play button)."
    exit 0
  fi
  echo "::error::App is running but the home screen did not render"
  grep -o 'content-desc="[^"]*"\|text="[^"]*"' ui.xml | sort -u | head -40
  exit 1
fi
echo "::error::App process died after launch"
grep -E "$pkg|ActivityManager: Process|AndroidRuntime|FATAL|libc  " logcat.txt | tail -n 60
exit 1
