/// Native-grade camera for SocialScoreKeeper.
///
/// [DaylightCamera] is a stateless forwarder over the Pigeon host API
/// (REQ-CAMERA-2026-001-068): each public method makes exactly one host-API
/// call and holds no state of its own. The camera session's state lives in
/// the native code.
library;

import 'package:flutter/foundation.dart';

import 'src/messages.g.dart';

/// The Dart entry point to the native camera.
class DaylightCamera {
  /// Creates a forwarder that talks to the native plugin.
  DaylightCamera() : _hostApi = DaylightCameraHostApi();

  /// Creates a forwarder over [hostApi], for tests that answer the channel.
  @visibleForTesting
  DaylightCamera.withHostApi(DaylightCameraHostApi hostApi) : _hostApi = hostApi;

  final DaylightCameraHostApi _hostApi;

  /// Asks the native side to warm up. Completes when the native side answers;
  /// a native error arrives as a `PlatformException`.
  Future<void> warmUp() => _hostApi.warmUp();
}
