package tech.daylightcreative.daylight_camera

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger

/** Registers the Pigeon host API on attach and removes it on detach. */
class DaylightCameraPlugin : FlutterPlugin, DaylightCameraHostApi {
  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    attach(binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    detach(binding.binaryMessenger)
  }

  internal fun attach(messenger: BinaryMessenger) {
    DaylightCameraHostApi.setUp(messenger, this)
  }

  internal fun detach(messenger: BinaryMessenger) {
    DaylightCameraHostApi.setUp(messenger, null)
  }

  // The contract's first method answers without camera work; chunk 22 of PRD
  // CAMERA-2026-001 gives it the CameraX warm-up.
  override fun warmUp(callback: (Result<Unit>) -> Unit) {
    callback(Result.success(Unit))
  }
}
