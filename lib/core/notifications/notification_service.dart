import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import 'notification_channels.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the system notification tray.
  // No additional processing needed.
}

class NotificationService {
  final _logger = Logger(printer: SimplePrinter());
  final _localNotifications = FlutterLocalNotificationsPlugin();

  FirebaseMessaging? _messaging;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      _logger.w('Firebase not configured, push notifications disabled: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _localNotifications.initialize(initSettings);

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          NotificationChannels.messagesId,
          NotificationChannels.messagesName,
          description: NotificationChannels.messagesDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  Future<NotificationSettings?> requestPermission() async {
    if (_messaging == null) return null;
    return _messaging!.requestPermission();
  }

  Future<String?> getToken() async {
    if (_messaging == null) return null;
    try {
      return await _messaging!.getToken();
    } catch (e) {
      _logger.w('Failed to get FCM token: $e');
      return null;
    }
  }

  Stream<String>? get onTokenRefresh => _messaging?.onTokenRefresh;

  Future<void> showNotification({
    required String title,
    required String body,
    String? channelId,
    String? postId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.messagesId,
      NotificationChannels.messagesName,
      channelDescription: NotificationChannels.messagesDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final payload =
        channelId != null ? jsonEncode({'channelId': channelId}) : null;

    await _localNotifications.show(
      postId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
