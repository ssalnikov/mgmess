import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mgmess/core/notifications/notification_service.dart';

/// Фейковый NotificationService — не использует Firebase / FlutterLocalNotifications.
class FakeNotificationService extends NotificationService {
  final List<Map<String, String>> shownNotifications = [];

  @override
  bool get isInitialized => false;

  @override
  Future<void> init() async {
    // no-op
  }

  @override
  Future<NotificationSettings?> requestPermission() async => null;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String>? get onTokenRefresh => null;

  @override
  Future<void> showNotification({
    required String title,
    required String body,
    String? channelId,
    String? postId,
  }) async {
    shownNotifications.add({
      'title': title,
      'body': body,
      if (channelId != null) 'channelId': channelId,
      if (postId != null) 'postId': postId,
    });
  }
}
