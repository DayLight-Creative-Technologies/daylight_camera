import 'package:daylight_camera/daylight_camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the native plugin answers warmUp on a device', (tester) async {
    await expectLater(DaylightCamera().warmUp(), completes);
  });
}
