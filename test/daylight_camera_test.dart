import 'package:daylight_camera/daylight_camera.dart';
import 'package:daylight_camera/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _warmUpChannel =
    'dev.flutter.pigeon.daylight_camera.DaylightCameraHostApi.warmUp';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = DaylightCameraHostApi.pigeonChannelCodec;

  tearDown(() => messenger.setMockMessageHandler(_warmUpChannel, null));

  test('warmUp sends exactly one message on the warmUp host channel and '
      'completes when the native side answers', () async {
    var messages = 0;
    messenger.setMockMessageHandler(_warmUpChannel, (ByteData? message) async {
      messages++;
      return codec.encodeMessage(<Object?>[null]);
    });

    await DaylightCamera().warmUp();

    expect(messages, 1);
  });

  test('warmUp surfaces a native error as a PlatformException carrying its '
      'code and message', () async {
    messenger.setMockMessageHandler(_warmUpChannel, (ByteData? message) async {
      return codec.encodeMessage(<Object?>['camera-busy', 'in use', null]);
    });

    await expectLater(
      DaylightCamera().warmUp(),
      throwsA(
        isA<PlatformException>()
            .having((e) => e.code, 'code', 'camera-busy')
            .having((e) => e.message, 'message', 'in use'),
      ),
    );
  });

  test('warmUp fails with channel-error when no native handler is '
      'registered, instead of hanging', () async {
    await expectLater(
      DaylightCamera().warmUp(),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'channel-error'),
      ),
    );
  });
}
