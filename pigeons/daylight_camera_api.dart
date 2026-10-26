// The only Pigeon input of daylight_camera (REQ-CAMERA-2026-001-064).
//
// Regenerate after any change with `tool/generate_pigeon.sh`, and commit the
// three generated files with this one. CI's `tool/check_pigeon_sync.sh` fails
// when they differ from what this file generates.
//
// This file holds the contract's first method only. PRD CAMERA-2026-001
// chunk 18 defines the full contract (REQ-CAMERA-2026-001-067) once the
// device spikes (chunks 13-17) have fixed what the native sessions can do.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartPackageName: 'daylight_camera',
    swiftOut: 'ios/daylight_camera/Sources/daylight_camera/Messages.g.swift',
    kotlinOut:
        'android/src/main/kotlin/tech/daylightcreative/daylight_camera/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'tech.daylightcreative.daylight_camera',
    ),
  ),
)
/// Commands Dart sends to the native camera.
@HostApi()
abstract class DaylightCameraHostApi {
  /// Prepares the native camera stack so a later open starts faster.
  ///
  /// The native sides answer success without camera work until PRD
  /// CAMERA-2026-001 chunks 19 (iOS) and 22 (Android) implement the warm-up.
  ///
  /// `@asyncCallback`, not `@async`: Pigeon 29's `@async` Swift output wraps
  /// each handler in a `Task` that sends the non-Sendable API and reply into
  /// it, which the Swift 6 language mode rejects (SendingRisksDataRace).
  @asyncCallback
  void warmUp();
}
