#!/usr/bin/env bash
# Fails when the plugin's native code observes the app going to the background
# (REQ-CAMERA-2026-001-064). Stopping the camera when the app leaves the
# foreground has exactly one owner, the Dart controller
# (REQ-CAMERA-2026-001-111); a native observer would be a second, unordered
# stop path.
#
# Flagged in iOS sources (ios/daylight_camera/Sources/**/*.swift):
#   didEnterBackgroundNotification, willResignActiveNotification,
#   applicationDidEnterBackground, applicationWillResignActive,
#   sceneDidEnterBackground, sceneWillResignActive
# Flagged in Android sources (android/src/main/**/*.kt, *.java):
#   ProcessLifecycleOwner, ON_PAUSE, ON_STOP, a declared onPause(...) or onStop(...)
# A DefaultLifecycleObserver that overrides only onResume (the location
# re-read of REQ-CAMERA-2026-001-067) is not flagged.
#
# Usage: tool/check_no_lifecycle_stop.sh [plugin root]   (default: this script's repo)
# Exit: 0 clean · 1 a lifecycle-stop observer was found · 2 a source tree is missing
set -uo pipefail

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
ios_src="$root/ios/daylight_camera/Sources"
android_src="$root/android/src/main"

for dir in "$ios_src" "$android_src"; do
  if [ ! -d "$dir" ]; then
    echo "COULD NOT VERIFY — source directory $dir is missing"
    exit 2
  fi
done

ios_pattern='didEnterBackgroundNotification|willResignActiveNotification|applicationDidEnterBackground|applicationWillResignActive|sceneDidEnterBackground|sceneWillResignActive'
# Word boundaries are spelled out: BSD grep (macOS) and GNU grep (CI) agree on these.
android_pattern='ProcessLifecycleOwner|(^|[^A-Za-z0-9_])ON_(PAUSE|STOP)([^A-Za-z0-9_]|$)|(^|[^A-Za-z0-9_])(fun|void)[[:space:]]+on(Pause|Stop)[[:space:]]*\('

findings="$(
  grep -rnE --include='*.swift' "$ios_pattern" "$ios_src"
  grep -rnE --include='*.kt' --include='*.java' "$android_pattern" "$android_src"
)"

if [ -n "$findings" ]; then
  echo "$findings"
  echo "FAIL — native code observes the app leaving the foreground; the Dart controller is the only owner of the lifecycle stop (REQ-CAMERA-2026-001-111)"
  exit 1
fi

echo "PASS — no iOS or Android source observes the app leaving the foreground"
exit 0
