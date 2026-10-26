#!/usr/bin/env bash
# Fails when the committed Pigeon output differs from what
# pigeons/daylight_camera_api.dart generates (REQ-CAMERA-2026-001-064).
#
# It never writes over the committed files: it copies the package's pubspec,
# lock file, package config and pigeons/ into a temporary directory, runs Pigeon
# there with the input file's own @ConfigurePigeon output paths, and compares
# the three outputs byte for byte with the committed ones.
#
# Usage: tool/check_pigeon_sync.sh [plugin root]   (default: this script's repo)
# Exit: 0 in sync · 1 a generated file differs or is missing · 2 could not generate
set -uo pipefail

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$root" || { echo "COULD NOT VERIFY — no plugin root at $root"; exit 2; }

dart_file='lib/src/messages.g.dart'
swift_file='ios/daylight_camera/Sources/daylight_camera/Messages.g.swift'
kotlin_file='android/src/main/kotlin/tech/daylightcreative/daylight_camera/Messages.g.kt'

for input in pubspec.yaml pubspec.lock .dart_tool/package_config.json pigeons/daylight_camera_api.dart; do
  if [ ! -f "$input" ]; then
    echo "COULD NOT VERIFY — $root/$input is missing (run flutter pub get)"
    exit 2
  fi
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/.dart_tool" "$tmp/pigeons"
cp pubspec.yaml pubspec.lock "$tmp/"
cp .dart_tool/package_config.json "$tmp/.dart_tool/"
cp pigeons/daylight_camera_api.dart "$tmp/pigeons/"
for out in "$dart_file" "$swift_file" "$kotlin_file"; do
  mkdir -p "$tmp/$(dirname "$out")"
done

if ! (cd "$tmp" && dart run pigeon --input pigeons/daylight_camera_api.dart) > "$tmp/pigeon.log" 2>&1; then
  cat "$tmp/pigeon.log"
  echo "COULD NOT VERIFY — pigeon failed to generate from pigeons/daylight_camera_api.dart"
  exit 2
fi

status=0
for committed in "$dart_file" "$swift_file" "$kotlin_file"; do
  generated="$tmp/$committed"
  if [ ! -f "$generated" ]; then
    echo "COULD NOT VERIFY — pigeon wrote no $committed"
    exit 2
  fi
  if [ ! -f "$committed" ]; then
    echo "FAIL — $committed is missing; run tool/generate_pigeon.sh and commit the output"
    status=1
  elif ! diff -u "$committed" "$generated"; then
    echo "FAIL — $committed differs from what pigeons/daylight_camera_api.dart generates; run tool/generate_pigeon.sh and commit the output"
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "PASS — the committed Dart, Swift and Kotlin Pigeon output matches pigeons/daylight_camera_api.dart"
fi
exit "$status"
