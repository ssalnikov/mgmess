import 'dart:async';
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

/// Payload extracted from a notification the user tapped on.
class NotificationTapPayload {
  final String? channelId;
  final String? postId;

  /// Account ID from a local notification (WS-generated).
  final String? accountId;

  /// Server URL from an FCM push notification.
  final String? serverUrl;

  const NotificationTapPayload({
    this.channelId,
    this.postId,
    this.accountId,
    this.serverUrl,
  });
}

class NotificationService {
  final _logger = Logger(printer: SimplePrinter());
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<NotificationTapPayload>.broadcast();

  FirebaseMessaging? _messaging;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Stream of payloads from tapped notifications (local or FCM).
  Stream<NotificationTapPayload> get onNotificationTap => _tapController.stream;

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
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

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

    // Handle FCM notification taps when app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_onFcmMessageTap);

    // Handle FCM notification tap that launched the app from terminated state.
    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      _onFcmMessageTap(initialMessage);
    }

    _initialized = true;
  }

  /// Handle tap on a local notification (generated from WS events).
  void _onLocalNotificationTap(NotificationResponse response) {
    final payloadStr = response.payload;
    if (payloadStr == null || payloadStr.isEmpty) return;

    try {
      final data = jsonDecode(payloadStr) as Map<String, dynamic>;
      _tapController.add(NotificationTapPayload(
        channelId: data['channelId'] as String?,
        accountId: data['accountId'] as String?,
      ));
    } catch (e) {
      _logger.w('Failed to parse local notification payload: $e');
    }
  }

  /// Handle tap on an FCM push notification (background or terminated).
  void _onFcmMessageTap(RemoteMessage message) {
    final data = message.data;
    _tapController.add(NotificationTapPayload(
      channelId: data['channel_id'] as String?,
      postId: data['post_id'] as String?,
      serverUrl: data['server_url'] as String?,
    ));
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
    String? accountId,
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

    final payloadMap = <String, String>{};
    if (channelId != null) payloadMap['channelId'] = channelId;
    if (accountId != null) payloadMap['accountId'] = accountId;
    final payload = payloadMap.isNotEmpty ? jsonEncode(payloadMap) : null;

    await _localNotifications.show(
      postId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void dispose() {
    _tapController.close();
  }
}
