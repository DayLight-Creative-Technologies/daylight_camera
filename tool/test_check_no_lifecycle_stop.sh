#!/usr/bin/env bash
# Pins tool/check_no_lifecycle_stop.sh: every observer it exists to refuse turns
# it red at the line that holds it, the onResume-only DefaultLifecycleObserver
# control and the near-miss names stay green, a missing source tree is exit 2,
# and the real tree passes.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
check="$here/check_no_lifecycle_stop.sh"
real_root="$(cd "$here/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0

# A plugin root holding one fixture file at the given relative path.
make_root() {
  local name="$1" rel="$2" body="$3"
  local root="$work/$name"
  mkdir -p "$root/ios/daylight_camera/Sources/daylight_camera" "$root/android/src/main/kotlin/x"
  mkdir -p "$(dirname "$root/$rel")"
  printf '%s\n' "$body" > "$root/$rel"
  echo "$root"
}

# expect <name> <expected exit> <root> [text the output must contain]
expect() {
  local name="$1" want="$2" root="$3" needle="${4:-}"
  cases=$((cases + 1))
  local out code
  out="$("$check" "$root" 2>&1)"
  code=$?
  if [ "$code" -ne "$want" ]; then
    echo "FAIL [$name]: exit $code, wanted $want"
    echo "$out"
    failures=$((failures + 1))
  elif [ -n "$needle" ] && ! grep -qF -- "$needle" <<< "$out"; then
    echo "FAIL [$name]: output does not name $needle"
    echo "$out"
    failures=$((failures + 1))
  fi
}

swift='ios/daylight_camera/Sources/daylight_camera/Fixture.swift'
kotlin='android/src/main/kotlin/x/Fixture.kt'
java='android/src/main/kotlin/x/Fixture.java'

# --- Refused: each observer turns the check red, naming its file and line. ---
expect 'iOS didEnterBackgroundNotification' 1 "$(make_root bg "$swift" 'import UIKit
NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in }')" "Fixture.swift:2:"
expect 'iOS willResignActiveNotification (shorthand)' 1 "$(make_root resign "$swift" 'center.addObserver(self, selector: #selector(stop), name: .willResignActiveNotification, object: nil)')" "Fixture.swift:1:"
expect 'iOS applicationDidEnterBackground delegate' 1 "$(make_root appbg "$swift" 'public func applicationDidEnterBackground(_ application: UIApplication) { stop() }')" "Fixture.swift:1:"
expect 'iOS applicationWillResignActive delegate' 1 "$(make_root appresign "$swift" 'public func applicationWillResignActive(_ application: UIApplication) { stop() }')" "Fixture.swift:1:"
expect 'iOS sceneDidEnterBackground delegate' 1 "$(make_root scenebg "$swift" 'public func sceneDidEnterBackground(_ scene: UIScene) { stop() }')" "Fixture.swift:1:"
expect 'iOS sceneWillResignActive delegate' 1 "$(make_root sceneresign "$swift" 'public func sceneWillResignActive(_ scene: UIScene) { stop() }')" "Fixture.swift:1:"
expect 'Android ProcessLifecycleOwner' 1 "$(make_root process "$kotlin" 'ProcessLifecycleOwner.get().lifecycle.addObserver(observer)')" "Fixture.kt:1:"
expect 'Android Lifecycle.Event.ON_PAUSE' 1 "$(make_root onpause "$kotlin" 'if (event == Lifecycle.Event.ON_PAUSE) stop()')" "Fixture.kt:1:"
expect 'Android imported ON_STOP' 1 "$(make_root onstop "$kotlin" 'when (event) { ON_STOP -> stop() else -> Unit }')" "Fixture.kt:1:"
expect 'Android observer onPause override' 1 "$(make_root obspause "$kotlin" 'object : DefaultLifecycleObserver {
  override fun onPause(owner: LifecycleOwner) { stop() }
}')" "Fixture.kt:2:"
expect 'Android observer onStop override' 1 "$(make_root obsstop "$kotlin" 'override fun onStop(owner: LifecycleOwner) = stop()')" "Fixture.kt:1:"
expect 'Android Java onPause' 1 "$(make_root javapause "$java" 'public void onPause(@NonNull LifecycleOwner owner) { stop(); }')" "Fixture.java:1:"

# --- Allowed: the onResume-only observer control and near-miss names. ---
expect 'onResume-only DefaultLifecycleObserver control' 0 "$(make_root control "$kotlin" 'import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter

class LocationRereadObserver(private val reread: () -> Unit) : DefaultLifecycleObserver {
  override fun onResume(owner: LifecycleOwner) = reread()
}

fun register(binding: ActivityPluginBinding, observer: LocationRereadObserver) {
  FlutterLifecycleAdapter.getActivityLifecycle(binding).addObserver(observer)
}')" "PASS"
expect 'near-miss names' 0 "$(make_root nearmiss "$kotlin" 'fun onPauseButtonTapped() = Unit
val ON_PAUSED_STATE = 1
val resumeAfterON_STOPPED = 2')" "PASS"

# --- Could not verify: a missing source tree is never a pass. ---
missing="$work/missing"
mkdir -p "$missing/android/src/main"
expect 'missing iOS sources' 2 "$missing" "COULD NOT VERIFY"

# --- The real tree is clean. ---
expect 'the real tree' 0 "$real_root" "PASS"

if [ "$failures" -ne 0 ]; then
  echo "FAIL — $failures of $cases check_no_lifecycle_stop.sh case(s) failed"
  exit 1
fi
echo "PASS — check_no_lifecycle_stop.sh refuses every lifecycle-stop observer at its line, keeps the onResume-only control and near-miss names green, refuses a missing tree (exit 2) and passes the real tree ($cases cases)"
