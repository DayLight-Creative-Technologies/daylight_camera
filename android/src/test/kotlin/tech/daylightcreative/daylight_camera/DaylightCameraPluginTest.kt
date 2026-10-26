package tech.daylightcreative.daylight_camera

import io.flutter.plugin.common.BinaryMessenger
import java.nio.ByteBuffer
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

private const val WARM_UP_CHANNEL =
  "dev.flutter.pigeon.daylight_camera.DaylightCameraHostApi.warmUp"

/** Records the handlers a plugin registers, so a test can call them. */
private class RecordingMessenger : BinaryMessenger {
  val handlers = mutableMapOf<String, BinaryMessenger.BinaryMessageHandler?>()

  override fun send(channel: String, message: ByteBuffer?) = Unit

  override fun send(
    channel: String,
    message: ByteBuffer?,
    callback: BinaryMessenger.BinaryReply?,
  ) = Unit

  override fun setMessageHandler(
    channel: String,
    handler: BinaryMessenger.BinaryMessageHandler?,
  ) {
    handlers[channel] = handler
  }
}

internal class DaylightCameraPluginTest {
  @Test
  fun attachRegistersWarmUpAndItAnswersSuccess() {
    val messenger = RecordingMessenger()
    DaylightCameraPlugin().attach(messenger)

    val handler = assertNotNull(messenger.handlers[WARM_UP_CHANNEL])
    var reply: Any? = "no reply"
    handler.onMessage(DaylightCameraHostApi.codec.encodeMessage(null)) { bytes ->
      bytes!!.rewind()
      reply = DaylightCameraHostApi.codec.decodeMessage(bytes)
    }

    assertEquals(listOf<Any?>(null), reply)
  }

  @Test
  fun detachRemovesTheWarmUpHandler() {
    val messenger = RecordingMessenger()
    val plugin = DaylightCameraPlugin()
    plugin.attach(messenger)

    plugin.detach(messenger)

    assertTrue(messenger.handlers.containsKey(WARM_UP_CHANNEL))
    assertNull(messenger.handlers[WARM_UP_CHANNEL])
  }
}
