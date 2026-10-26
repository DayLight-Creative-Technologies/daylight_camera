import Flutter
import XCTest

@testable import daylight_camera

private let warmUpChannel = "dev.flutter.pigeon.daylight_camera.DaylightCameraHostApi.warmUp"

/// Records the handlers a plugin registers, so a test can call them.
private final class RecordingMessenger: NSObject, FlutterBinaryMessenger {
  var handlers: [String: FlutterBinaryMessageHandler] = [:]
  var clearedChannels: [String] = []

  func send(onChannel channel: String, message: Data?) {}

  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {}

  func setMessageHandlerOnChannel(
    _ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?
  ) -> FlutterBinaryMessengerConnection {
    if let handler {
      handlers[channel] = handler
    } else {
      handlers[channel] = nil
      clearedChannels.append(channel)
    }
    return 1
  }

  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}
}

final class RunnerTests: XCTestCase {
  func testAttachRegistersWarmUpAndItAnswersSuccess() throws {
    let messenger = RecordingMessenger()
    DaylightCameraPlugin().attach(to: messenger)

    let handler = try XCTUnwrap(messenger.handlers[warmUpChannel])
    let codec = DaylightCameraHostApiSetup.codec
    let answered = expectation(description: "warmUp replies")
    var reply: [Any?]?
    handler(codec.encode(nil)) { data in
      reply = codec.decode(data) as? [Any?]
      answered.fulfill()
    }
    wait(for: [answered], timeout: 5)

    let values = try XCTUnwrap(reply)
    XCTAssertEqual(values.count, 1)
    XCTAssertTrue(values[0] == nil || values[0] is NSNull)
  }

  func testDetachRemovesTheWarmUpHandler() {
    let messenger = RecordingMessenger()
    let plugin = DaylightCameraPlugin()
    plugin.attach(to: messenger)

    plugin.detach(from: messenger)

    XCTAssertNil(messenger.handlers[warmUpChannel])
    XCTAssertEqual(messenger.clearedChannels, [warmUpChannel])
  }
}
