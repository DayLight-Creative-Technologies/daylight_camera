import 'package:daylight_camera/daylight_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ExampleApp());
}

/// Builds the plugin into a real app, so CI and `flutter build` prove its
/// packaging, and offers a button that calls the native side.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final DaylightCamera _camera = DaylightCamera();
  String _status = 'Not warmed up';

  Future<void> _warmUp() async {
    String status;
    try {
      await _camera.warmUp();
      status = 'Warm-up answered';
    } on PlatformException catch (error) {
      status = 'Warm-up failed: ${error.code}';
    }
    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('daylight_camera example')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_status),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _warmUp, child: const Text('Warm up')),
            ],
          ),
        ),
      ),
    );
  }
}
