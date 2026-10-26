#!/usr/bin/env bash
# Pins tool/check_pigeon_sync.sh on copies of this package: the committed
# output passes; a hand edit to each generated file, a deleted generated file
# and an input edited without regenerating each fail naming the file; a broken
# input is exit 2; the check never writes over the committed files.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
real_root="$(cd "$here/.." && pwd)"
check="$here/check_pigeon_sync.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0
cases=0

dart_file='lib/src/messages.g.dart'
swift_file='ios/daylight_camera/Sources/daylight_camera/Messages.g.swift'
kotlin_file='android/src/main/kotlin/tech/daylightcreative/daylight_camera/Messages.g.kt'
input='pigeons/daylight_camera_api.dart'

# A copy of the files the check reads, with the package config rewritten so the
# root package resolves to the copy.
copy_root() {
  local root="$work/$1"
  mkdir -p "$root/.dart_tool"
  for f in pubspec.yaml pubspec.lock "$input" "$dart_file" "$swift_file" "$kotlin_file"; do
    mkdir -p "$root/$(dirname "$f")"
    cp "$real_root/$f" "$root/$f"
  done
  cp "$real_root/.dart_tool/package_config.json" "$root/.dart_tool/"
  echo "$root"
}

expect() {
  local name="$1" want="$2" root="$3" needle="${4:-}"
  cases=$((cases + 1))
  local out code
  out="$("$check" "$root" 2>&1)"
  code=$?
  if [ "$code" -ne "$want" ]; then
    echo "FAIL [$name]: exit $code, wanted $want"
    echo "$out" | tail -20
    failures=$((failures + 1))
  elif [ -n "$needle" ] && ! grep -qF -- "$needle" <<< "$out"; then
    echo "FAIL [$name]: output does not name $needle"
    echo "$out" | tail -20
    failures=$((failures + 1))
  fi
}

expect 'committed output in sync' 0 "$(copy_root clean)" "PASS"

for f in "$dart_file" "$swift_file" "$kotlin_file"; do
  root="$(copy_root "edit-$(basename "$f")")"
  printf '\n// hand edit\n' >> "$root/$f"
  expect "hand-edited $(basename "$f")" 1 "$root" "FAIL — $f differs"
done

root="$(copy_root deleted)"
rm "$root/$swift_file"
expect 'deleted generated Swift file' 1 "$root" "FAIL — $swift_file is missing"

root="$(copy_root stale-input)"
perl -pi -e 's/^  void warmUp\(\);$/  void warmUp();\n\n  \@async\n  void coolDown();/' "$root/$input"
if ! grep -q 'void coolDown();' "$root/$input"; then
  echo "FAIL [input changed without regenerating]: the fixture edit did not apply"
  failures=$((failures + 1))
fi
expect 'input changed without regenerating' 1 "$root" "FAIL — $dart_file differs"

root="$(copy_root broken-input)"
printf 'this is not dart\n' > "$root/$input"
expect 'input that does not parse' 2 "$root" "COULD NOT VERIFY"

# The check leaves the files it compares untouched.
before="$(cat "$real_root/$dart_file" "$real_root/$swift_file" "$real_root/$kotlin_file" | shasum)"
root="$(copy_root untouched)"
printf '\n// hand edit\n' >> "$root/$kotlin_file"
expected_after="$(cat "$root/$kotlin_file" | shasum)"
"$check" "$root" > /dev/null 2>&1
cases=$((cases + 1))
if [ "$(cat "$root/$kotlin_file" | shasum)" != "$expected_after" ]; then
  echo "FAIL [never writes]: the check rewrote the file it compares"
  failures=$((failures + 1))
fi
if [ "$(cat "$real_root/$dart_file" "$real_root/$swift_file" "$real_root/$kotlin_file" | shasum)" != "$before" ]; then
  echo "FAIL [never writes]: the real generated files changed"
  failures=$((failures + 1))
fi

expect 'the real tree' 0 "$real_root" "PASS"

if [ "$failures" -ne 0 ]; then
  echo "FAIL — $failures of $cases check_pigeon_sync.sh case(s) failed"
  exit 1
fi
echo "PASS — check_pigeon_sync.sh fails on a hand edit to each generated file, a deleted one and an unregenerated input, refuses an unparseable input (exit 2), never writes over what it compares, and passes the real tree ($cases cases)"
