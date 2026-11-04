import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class InAppNotificationItem {
  InAppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.data,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic>? data;
}

class FirebaseNotificationService {
  FirebaseNotificationService({FirebaseMessaging? messaging}) : _messaging = messaging;

  final FirebaseMessaging? _messaging;
  final List<InAppNotificationItem> _receivedNotifications = [];

  List<InAppNotificationItem> get receivedNotifications => List.unmodifiable(_receivedNotifications);

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseMessaging get messagingInstance => _messaging ?? FirebaseMessaging.instance;

  Future<void> initialize({void Function(InAppNotificationItem notification)? onNotificationTapped}) async {
    if (!_isFirebaseReady) {
      // Add a mock welcome notification for demonstration
      _receivedNotifications.add(
        InAppNotificationItem(
          id: 'mock_notif_001',
          title: 'Điểm danh lớp PRM393',
          body: 'Giảng viên đã mở phiên điểm danh cho ca học sáng nay.',
          receivedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      );
      return;
    }

    try {
      // Request notification permission for Android 13+ / iOS
      final settings = await messagingInstance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM Notification permission status: ${settings.authorizationStatus}');

      _fcmToken = await messagingInstance.getToken();
      debugPrint('FCM Device Token: $_fcmToken');

      // 1. Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notif = InAppNotificationItem(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification?.title ?? 'Thông báo lớp học',
          body: message.notification?.body ?? '',
          receivedAt: DateTime.now(),
          data: message.data,
        );
        _receivedNotifications.insert(0, notif);
      });

      // 2. Background message open
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final notif = InAppNotificationItem(
          id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification?.title ?? 'Thông báo lớp học',
          body: message.notification?.body ?? '',
          receivedAt: DateTime.now(),
          data: message.data,
        );
        onNotificationTapped?.call(notif);
      });

      // 3. Terminated message open
      final initialMessage = await messagingInstance.getInitialMessage();
      if (initialMessage != null) {
        final notif = InAppNotificationItem(
          id: initialMessage.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: initialMessage.notification?.title ?? 'Thông báo lớp học',
          body: initialMessage.notification?.body ?? '',
          receivedAt: DateTime.now(),
          data: initialMessage.data,
        );
        onNotificationTapped?.call(notif);
      }
    } catch (e) {
      debugPrint('FCM setup error: $e');
    }
  }

  void addManualNotification(String title, String body) {
    _receivedNotifications.insert(
      0,
      InAppNotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        receivedAt: DateTime.now(),
      ),
    );
  }
}
