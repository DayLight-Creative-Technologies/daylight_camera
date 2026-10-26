import Flutter

/// Registers the Pigeon host API on attach and removes it on detach.
public final class DaylightCameraPlugin: NSObject, FlutterPlugin, DaylightCameraHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = DaylightCameraPlugin()
    instance.attach(to: registrar.messenger())
    // Publishing makes the engine call detachFromEngine(for:) on teardown.
    registrar.publish(instance)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    detach(from: registrar.messenger())
  }

  func attach(to messenger: FlutterBinaryMessenger) {
    DaylightCameraHostApiSetup.setUp(binaryMessenger: messenger, api: self)
  }

  func detach(from messenger: FlutterBinaryMessenger) {
    DaylightCameraHostApiSetup.setUp(binaryMessenger: messenger, api: nil)
  }

  // The contract's first method answers without camera work; chunk 19 of PRD
  // CAMERA-2026-001 gives it the AVFoundation warm-up.
  func warmUp(completion: @escaping (Result<Void, Error>) -> Void) {
    completion(.success(()))
  }
}
