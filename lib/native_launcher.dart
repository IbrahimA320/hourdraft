import 'package:flutter/services.dart';

class NativeLauncher {
  // Define a unique channel name
  static const _channel = MethodChannel('com.example.app/launcher');

  static Future<void> launchURL(String urlString) async {
    try {
      await _channel.invokeMethod('openUrl', {'url': urlString});
    } on PlatformException catch (e) {
      print("Failed to launch URL: ${e.message}");
    }
  }
}