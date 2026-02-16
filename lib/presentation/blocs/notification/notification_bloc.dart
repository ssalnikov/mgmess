import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/websocket_events.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  final NotificationService _notificationService;
  final _logger = Logger(printer: SimplePrinter());

  StreamSubscription<String>? _tokenRefreshSub;
  String? _activeChannelId;
  String? _currentUserId;

  static const _prefKeyEnabled = 'notification_enabled';
  static const _prefKeyFilter = 'notification_filter';

  NotificationBloc({
    required NotificationRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService,
        super(const NotificationInitial()) {
    on<NotificationInit>(_onInit);
    on<NotificationTokenRefreshed>(_onTokenRefreshed);
    on<NotificationWsEvent>(_onWsEvent);
    on<NotificationSetActiveChannel>(_onSetActiveChannel);
    on<NotificationClearActiveChannel>(_onClearActiveChannel);
    on<NotificationLogout>(_onLogout);
  }

  Future<void> _onInit(
    NotificationInit event,
    Emitter<NotificationState> emit,
  ) async {
    _currentUserId = event.userId;

    if (!_notificationService.isInitialized) {
      emit(const NotificationReady(enabled: false));
      return;
    }

    final settings = await _notificationService.requestPermission();
    if (settings == null) {
      emit(const NotificationReady(enabled: false));
      return;
    }

    final token = await _notificationService.getToken();
    if (token != null) {
      await _repository.registerDeviceToken(token);
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _notificationService.onTokenRefresh?.listen((newToken) {
      add(NotificationTokenRefreshed(token: newToken));
    });

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefKeyEnabled) ?? true;

    emit(NotificationReady(token: token, enabled: enabled));
  }

  Future<void> _onTokenRefreshed(
    NotificationTokenRefreshed event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.registerDeviceToken(event.token);
    if (state is NotificationReady) {
      final current = state as NotificationReady;
      emit(NotificationReady(token: event.token, enabled: current.enabled));
    }
  }

  Future<void> _onWsEvent(
    NotificationWsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final wsEvent = event.wsEvent;
    if (wsEvent.event != WsEventType.posted) return;

    final currentState = state;
    if (currentState is! NotificationReady || !currentState.enabled) return;

    final channelId = wsEvent.channelId;
    if (channelId == null) return;

    // Don't show notification for the currently active channel
    if (channelId == _activeChannelId) return;

    final postJson = wsEvent.data['post'];
    if (postJson is! String) return;

    try {
      final post = jsonDecode(postJson) as Map<String, dynamic>;
      final senderId = post['user_id'] as String? ?? '';

      // Don't notify for own messages
      if (senderId == _currentUserId) return;

      final message = post['message'] as String? ?? '';
      if (message.isEmpty) return;

      // Apply notification filter
      final prefs = await SharedPreferences.getInstance();
      final filter = prefs.getString(_prefKeyFilter) ?? 'all';

      if (filter != 'all') {
        final channelType = wsEvent.data['channel_type'] as String? ?? '';
        final mentionsJson = wsEvent.data['mentions'] as String?;
        final isMentioned = mentionsJson != null &&
            _currentUserId != null &&
            mentionsJson.contains(_currentUserId!);
        final isDm = channelType == 'D' || channelType == 'G';

        if (filter == 'dm_only' && !isDm) return;
        if (filter == 'mentions_dm' && !isMentioned && !isDm) return;
      }

      final senderName = wsEvent.data['sender_name'] as String? ?? '';
      final channelDisplayName =
          wsEvent.data['channel_display_name'] as String? ?? '';

      final title =
          channelDisplayName.isNotEmpty ? channelDisplayName : senderName;

      final body = senderName.isNotEmpty ? '$senderName: $message' : message;

      await _notificationService.showNotification(
        title: title,
        body: body,
        channelId: channelId,
        postId: post['id'] as String?,
      );
    } catch (e) {
      _logger.w('Failed to show notification: $e');
    }
  }

  void _onSetActiveChannel(
    NotificationSetActiveChannel event,
    Emitter<NotificationState> emit,
  ) {
    _activeChannelId = event.channelId;
  }

  void _onClearActiveChannel(
    NotificationClearActiveChannel event,
    Emitter<NotificationState> emit,
  ) {
    _activeChannelId = null;
  }

  Future<void> _onLogout(
    NotificationLogout event,
    Emitter<NotificationState> emit,
  ) async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _activeChannelId = null;
    _currentUserId = null;
    await _repository.unregisterDevice();
    emit(const NotificationInitial());
  }

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    return super.close();
  }
}
