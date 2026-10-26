#!/usr/bin/env bash
# Regenerates the Dart, Swift and Kotlin bindings from pigeons/daylight_camera_api.dart,
# the only Pigeon input. The output paths live in that file's @ConfigurePigeon.
set -euo pipefail
cd "$(dirname "$0")/.."
dart run pigeon --input pigeons/daylight_camera_api.dart
