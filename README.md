# daylight_camera

The in-app camera of [SocialScoreKeeper](https://socialscorekeeper.com): AVFoundation on iOS, CameraX on Android, driven from Dart through one Pigeon contract. It is built for SocialScoreKeeper first and published under the MIT license.

This is the plugin's scaffold. Its host API has one method, `warmUp()`, which the native sides answer without camera work yet; the full contract and the capture engines arrive in later releases.

## Platforms

| | Minimum | Toolchain |
|---|---|---|
| iOS | 18.0 | Swift 6 language mode; Swift Package Manager (`ios/daylight_camera/Package.swift`) and CocoaPods (`ios/daylight_camera.podspec`) build the same sources |
| Android | API 24 | CameraX 1.6.2 on every `androidx.camera` artifact; AGP 9, the Kotlin Gradle Plugin is never applied by the module |

## Using it

SocialScoreKeeper pins it by commit:

```yaml
daylight_camera:
  git:
    url: https://github.com/DayLight-Creative-Technologies/daylight_camera.git
    ref: <full commit SHA with a green CI run>
```

```dart
final camera = DaylightCamera();
await camera.warmUp();
```

`DaylightCamera` holds no state: each method makes one host-API call, and a native error arrives as a `PlatformException`.

## Changing the contract

`pigeons/daylight_camera_api.dart` is the only Pigeon input. After editing it, run `tool/generate_pigeon.sh` and commit the regenerated Dart, Swift and Kotlin with it. Host methods use `@asyncCallback`: Pigeon 29's `@async` Swift output does not compile in the Swift 6 language mode.

## Checks

CI (`.github/workflows/ci.yml`) runs every job on every push, and all of them are required:

| Job | What it runs |
|---|---|
| Dart analyze | `dart analyze --fatal-infos` |
| Pigeon sync | `tool/test_check_pigeon_sync.sh`, then `tool/check_pigeon_sync.sh`: the committed generated files equal what the input generates |
| No lifecycle stop | `tool/test_check_no_lifecycle_stop.sh`, then `tool/check_no_lifecycle_stop.sh`: no native code observes the app going to the background (the Dart side owns that stop) |
| Riverpod scanner | `riverpod-3-scanner` over `lib/` |
| Flutter test | `flutter test` |
| iOS XCTest | the example app's `RunnerTests` on an iOS Simulator |
| Android unit tests | `./gradlew :daylight_camera:testDebugUnitTest` in `example/android` |

SocialScoreKeeper refuses to pin a commit unless all seven jobs passed on it, so renaming a job means updating that check too.
