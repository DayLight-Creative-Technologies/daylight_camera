# daylight_camera_example

A small app that builds `daylight_camera` the way a host app does, so CI and `flutter build` prove the plugin's packaging on both platforms. Its screen has one button that calls `warmUp()`.

- `ios/RunnerTests/RunnerTests.swift` is the plugin's XCTest target (CI job "iOS XCTest").
- `integration_test/plugin_integration_test.dart` checks that the native plugin answers on a real device: `flutter test integration_test` with a device attached.
