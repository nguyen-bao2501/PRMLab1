import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics}) : _analytics = analytics;

  final FirebaseAnalytics? _analytics;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAnalytics get analyticsInstance => _analytics ?? FirebaseAnalytics.instance;

  Future<void> setUserId(String? userId) async {
    if (_isFirebaseReady) {
      try {
        await analyticsInstance.setUserId(id: userId);
      } catch (e) {
        debugPrint('Analytics setUserId error: $e');
      }
    }
  }

  // Event 1: Login
  Future<void> logLogin({String method = 'google'}) async {
    if (_isFirebaseReady) {
      try {
        await analyticsInstance.logLogin(loginMethod: method);
      } catch (e) {
        debugPrint('Analytics logLogin error: $e');
      }
    }
    debugPrint('[Analytics] Event: login (method: $method)');
  }

  // Event 2: Logout
  Future<void> logLogout() async {
    if (_isFirebaseReady) {
      try {
        await analyticsInstance.logEvent(name: 'logout');
      } catch (e) {
        debugPrint('Analytics logLogout error: $e');
      }
    }
    debugPrint('[Analytics] Event: logout');
  }

  // Event 3: Search
  Future<void> logSearchClasses({required String searchTerm, required int resultCount}) async {
    if (_isFirebaseReady) {
      try {
        await analyticsInstance.logSearch(
          searchTerm: searchTerm,
          parameters: {'result_count': resultCount},
        );
      } catch (e) {
        debugPrint('Analytics logSearch error: $e');
      }
    }
    debugPrint('[Analytics] Event: search (searchTerm: $searchTerm, resultCount: $resultCount)');
  }

  // Event 4: View Class Detail
  Future<void> logViewClassDetail({required String classId, required String subjectCode}) async {
    if (_isFirebaseReady) {
      try {
        await analyticsInstance.logEvent(
          name: 'view_class_detail',
          parameters: {
            'class_id': classId,
            'subject_code': subjectCode,
          },
        );
      } catch (e) {
        debugPrint('Analytics logViewClassDetail error: $e');
      }
    }
    debugPrint('[Analytics] Event: view_class_detail ($subjectCode)');
  }

  // Event 5: View Schedule
  Future<void> logViewSchedule({required String selectedDate, required int sessionCount}) async {
    if (_isFirebaseReady) {
      try {
        await analyticsInstance.logEvent(
          name: 'view_schedule',
          parameters: {
            'date': selectedDate,
            'session_count': sessionCount,
          },
        );
      } catch (e) {
        debugPrint('Analytics logViewSchedule error: $e');
      }
    }
    debugPrint('[Analytics] Event: view_schedule ($selectedDate, sessions: $sessionCount)');
  }

  // Event 6: Start Live Attendance
  Future<void> logStartAttendance({required String sessionId, required int slot, required String room}) async {
    if (_isFirebaseReady) {
      try {
        await analyticsInstance.logEvent(
          name: 'start_live_attendance',
          parameters: {
            'session_id': sessionId,
            'slot': slot,
            'room': room,
          },
        );
      } catch (e) {
        debugPrint('Analytics logStartAttendance error: $e');
      }
    }
    debugPrint('[Analytics] Event: start_live_attendance (slot: $slot, room: $room)');
  }

  // Event 7: Export Attendance Report PDF
  Future<void> logExportReport({required String classCode, required int attendedCount, required int totalCount}) async {
    if (_isFirebaseReady) {
      try {
        await analyticsInstance.logEvent(
          name: 'export_attendance_report',
          parameters: {
            'class_code': classCode,
            'attended_count': attendedCount,
            'total_count': totalCount,
          },
        );
      } catch (e) {
        debugPrint('Analytics logExportReport error: $e');
      }
    }
    debugPrint('[Analytics] Event: export_attendance_report ($classCode, $attendedCount/$totalCount)');
  }
}
