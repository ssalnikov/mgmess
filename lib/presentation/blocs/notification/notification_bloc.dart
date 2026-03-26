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
  final String? _accountId;
  final String? _serverDisplayName;
  final _logger = Logger(printer: SimplePrinter());

  StreamSubscription<String>? _tokenRefreshSub;
  String? _activeChannelId;
  String? _currentUserId;
  Set<String> _mutedChannelIds = {};
  Map<String, String> _channelNotificationFilters = {};

  static const _prefKeyEnabled = 'notification_enabled';
  static const _prefKeyFilter = 'notification_filter';

  String get _channelPrefPrefix => _accountId != null
      ? 'channel_notification_${_accountId}_'
      : 'channel_notification_';

  NotificationBloc({
    required NotificationRepository repository,
    required NotificationService notificationService,
    String? accountId,
    String? serverDisplayName,
  })  : _repository = repository,
        _notificationService = notificationService,
        _accountId = accountId,
        _serverDisplayName = serverDisplayName,
        super(const NotificationInitial()) {
    on<NotificationInit>(_onInit);
    on<NotificationInitBackground>(_onInitBackground);
    on<NotificationTokenRefreshed>(_onTokenRefreshed);
    on<NotificationWsEvent>(_onWsEvent);
    on<NotificationSetActiveChannel>(_onSetActiveChannel);
    on<NotificationClearActiveChannel>(_onClearActiveChannel);
    on<NotificationLogout>(_onLogout);
    on<NotificationUpdateMutedChannels>(_onUpdateMutedChannels);
    on<NotificationChannelSettingChanged>(_onChannelSettingChanged);
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

    _loadChannelFilters(prefs);

    emit(NotificationReady(token: token, enabled: enabled));
  }

  /// Lightweight init for background sessions — sets userId, loads
  /// per-channel filters, but does NOT request permissions or register FCM.
  Future<void> _onInitBackground(
    NotificationInitBackground event,
    Emitter<NotificationState> emit,
  ) async {
    _currentUserId = event.userId;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefKeyEnabled) ?? true;

    _loadChannelFilters(prefs);

    emit(NotificationReady(enabled: enabled));
  }

  void _loadChannelFilters(SharedPreferences prefs) {
    _channelNotificationFilters = {};
    final prefix = _channelPrefPrefix;
    for (final key in prefs.getKeys()) {
      if (key.startsWith(prefix)) {
        final channelId = key.substring(prefix.length);
        final value = prefs.getString(key);
        if (value != null && value != 'default') {
          _channelNotificationFilters[channelId] = value;
        }
      }
    }
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

    // Don't show notification for muted channels
    if (_mutedChannelIds.contains(channelId)) return;

    final postJson = wsEvent.data['post'];
    if (postJson is! String) return;

    try {
      final post = jsonDecode(postJson) as Map<String, dynamic>;
      final senderId = post['user_id'] as String? ?? '';

      // Don't notify for own messages
      if (senderId == _currentUserId) return;

      final message = post['message'] as String? ?? '';
      if (message.isEmpty) return;

      // Apply per-channel notification filter first
      final channelFilter = _channelNotificationFilters[channelId];
      if (channelFilter != null) {
        if (channelFilter == 'none') return;
        if (channelFilter == 'mentions') {
          final mentionsJson = wsEvent.data['mentions'] as String?;
          final isMentioned = mentionsJson != null &&
              _currentUserId != null &&
              mentionsJson.contains(_currentUserId!);
          if (!isMentioned) return;
        }
        // 'all' — show everything, skip global filter
      } else {
        // Apply global notification filter
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
      }

      final senderName = wsEvent.data['sender_name'] as String? ?? '';
      final channelDisplayName =
          wsEvent.data['channel_display_name'] as String? ?? '';

      final baseTitle =
          channelDisplayName.isNotEmpty ? channelDisplayName : senderName;
      final title = _serverDisplayName != null && _serverDisplayName.isNotEmpty
          ? '[$_serverDisplayName] $baseTitle'
          : baseTitle;

      final body = senderName.isNotEmpty ? '$senderName: $message' : message;

      await _notificationService.showNotification(
        title: title,
        body: body,
        channelId: channelId,
        postId: post['id'] as String?,
        accountId: _accountId,
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

  void _onUpdateMutedChannels(
    NotificationUpdateMutedChannels event,
    Emitter<NotificationState> emit,
  ) {
    _mutedChannelIds = event.mutedChannelIds;
  }

  void _onChannelSettingChanged(
    NotificationChannelSettingChanged event,
    Emitter<NotificationState> emit,
  ) {
    if (event.filter == 'default') {
      _channelNotificationFilters.remove(event.channelId);
    } else {
      _channelNotificationFilters[event.channelId] = event.filter;
    }
  }

  Future<void> _onLogout(
    NotificationLogout event,
    Emitter<NotificationState> emit,
  ) async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _activeChannelId = null;
    _currentUserId = null;
    _mutedChannelIds = {};
    _channelNotificationFilters = {};
    await _repository.unregisterDevice();
    emit(const NotificationInitial());
  }

  @override
  Future<void> close() {
    _tokenRefreshSub?.cancel();
    return super.close();
  }
}
