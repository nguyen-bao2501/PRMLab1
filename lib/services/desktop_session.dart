import 'package:flutter/services.dart';

/// Windows Credential Manager stores the session for the current Windows user.
class DesktopSession {
  static const channel = MethodChannel('fpt_attendance/desktop');

  Future<String?> read() async {
    try {
      return await channel.invokeMethod<String>('readSession');
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> write(String value) async {
    try {
      await channel.invokeMethod<void>('writeSession', value);
    } on MissingPluginException {
      // Other platforms do not persist a session through this Windows bridge.
    }
  }

  Future<void> clear() async {
    try {
      await channel.invokeMethod<void>('clearSession');
    } on MissingPluginException {
      // No Windows credential exists on other platforms.
    }
  }

  static Future<void> focus() async {
    try {
      await channel.invokeMethod<void>('focus');
    } on PlatformException {
      // Foreground activation is best effort and must not fail authentication.
    } on MissingPluginException {
      // Not running in the Windows runner.
    }
  }
}
