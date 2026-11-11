import 'package:flutter/material.dart';
import '../firebase/firebase_analytics_service.dart';
import '../firebase/firebase_auth_service.dart';
import '../firebase/firebase_crashlytics_service.dart';
import '../firebase/firebase_notification_service.dart';
import '../firebase/firebase_remote_config_service.dart';
import '../firebase/firebase_storage_service.dart';

class FirebaseDemoViewModel extends ChangeNotifier {
  FirebaseDemoViewModel({
    required FirebaseAuthService authService,
    required FirebaseStorageService storageService,
    required FirebaseNotificationService notificationService,
    required FirebaseAnalyticsService analyticsService,
    required FirebaseCrashlyticsService crashlyticsService,
    required FirebaseRemoteConfigService remoteConfigService,
  })  : _authService = authService,
        _storageService = storageService,
        _notificationService = notificationService,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService,
        _remoteConfigService = remoteConfigService;

  final FirebaseAuthService _authService;
  final FirebaseStorageService _storageService;
  final FirebaseNotificationService _notificationService;
  final FirebaseAnalyticsService _analyticsService;
  final FirebaseCrashlyticsService _crashlyticsService;
  final FirebaseRemoteConfigService _remoteConfigService;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  List<InAppNotificationItem> get notifications => _notificationService.receivedNotifications;
  String? get fcmToken => _notificationService.fcmToken;
  FirebaseStorageService get storageService => _storageService;
  FirebaseAnalyticsService get analyticsService => _analyticsService;

  bool get ocrEnabled => _remoteConfigService.isOcrFeatureEnabled;
  int get syncInterval => _remoteConfigService.syncIntervalSeconds;
  String get announcementText => _remoteConfigService.announcementBannerText;

  Future<void> fetchRemoteConfig() async {
    _statusMessage = 'Đang đồng bộ cấu hình từ Firebase Remote Config...';
    notifyListeners();

    await _remoteConfigService.fetchAndActivate();
    _statusMessage = 'Đã cập nhật Remote Config thành công!';
    notifyListeners();
  }

  Future<void> sendTestNonFatalError() async {
    try {
      throw FormatException('Thử nghiệm ghi nhận handled non-fatal error trong Lab 3');
    } catch (e, stack) {
      await _crashlyticsService.recordNonFatalError(
        e,
        stack,
        reason: 'Lab 3 non-fatal verification error',
        customKeys: {
          'demo_key': 'PRM393_VERIFICATION',
          'user_role': _authService.currentUser?.role ?? 'LECTURER',
        },
      );
      _statusMessage = 'Đã gửi Non-Fatal Error kèm User ID & Custom Keys lên Crashlytics!';
      notifyListeners();
    }
  }

  void triggerTestCrash() {
    _crashlyticsService.triggerTestCrash();
  }

  void addMockPushNotification() {
    _notificationService.addManualNotification(
      'Nhắc nhở ca học chiều nay',
      'Tiết học PRN232 - Lớp SE1918 sẽ bắt đầu lúc 12:30 tại phòng A203.',
    );
    notifyListeners();
  }
}
