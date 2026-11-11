import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseCrashlyticsService {
  FirebaseCrashlyticsService({FirebaseCrashlytics? crashlytics}) : _crashlytics = crashlytics;

  final FirebaseCrashlytics? _crashlytics;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseCrashlytics get crashlyticsInstance => _crashlytics ?? FirebaseCrashlytics.instance;

  Future<void> setUserIdentifier(String userId) async {
    if (_isFirebaseReady) {
      try {
        await crashlyticsInstance.setUserIdentifier(userId);
      } catch (e) {
        debugPrint('Crashlytics setUserIdentifier error: $e');
      }
    }
  }

  Future<void> setCustomKey(String key, dynamic value) async {
    if (_isFirebaseReady) {
      try {
        await crashlyticsInstance.setCustomKey(key, value);
      } catch (e) {
        debugPrint('Crashlytics setCustomKey error: $e');
      }
    }
  }

  // 1. Handled Non-Fatal Error from a real error path
  Future<void> recordNonFatalError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    Map<String, dynamic>? customKeys,
  }) async {
    if (_isFirebaseReady) {
      try {
        if (customKeys != null) {
          for (final entry in customKeys.entries) {
            await crashlyticsInstance.setCustomKey(entry.key, entry.value);
          }
        }
        await crashlyticsInstance.recordError(
          exception,
          stack,
          reason: reason ?? 'Handled non-fatal error in application flow',
          fatal: false,
        );
      } catch (e) {
        debugPrint('Crashlytics recordNonFatalError error: $e');
      }
    }
    debugPrint('[Crashlytics] Recorded Non-Fatal Error: $exception (Reason: $reason)');
  }

  // 2. Test Crash trigger for verification
  void triggerTestCrash() {
    debugPrint('[Crashlytics] Triggering test crash...');
    if (_isFirebaseReady) {
      crashlyticsInstance.crash();
    } else {
      throw StateError('Simulated crash triggered for Lab 3 evaluation.');
    }
  }
}
