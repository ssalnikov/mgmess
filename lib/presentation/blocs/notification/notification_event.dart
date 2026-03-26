import 'package:equatable/equatable.dart';

import '../../../core/network/websocket_events.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationInit extends NotificationEvent {
  final String userId;

  const NotificationInit({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class NotificationTokenRefreshed extends NotificationEvent {
  final String token;

  const NotificationTokenRefreshed({required this.token});

  @override
  List<Object?> get props => [token];
}

class NotificationWsEvent extends NotificationEvent {
  final WsEvent wsEvent;

  const NotificationWsEvent({required this.wsEvent});

  @override
  List<Object?> get props => [wsEvent];
}

class NotificationSetActiveChannel extends NotificationEvent {
  final String channelId;

  const NotificationSetActiveChannel({required this.channelId});

  @override
  List<Object?> get props => [channelId];
}

class NotificationClearActiveChannel extends NotificationEvent {
  const NotificationClearActiveChannel();
}

class NotificationLogout extends NotificationEvent {
  const NotificationLogout();
}

class NotificationUpdateMutedChannels extends NotificationEvent {
  final Set<String> mutedChannelIds;

  const NotificationUpdateMutedChannels({required this.mutedChannelIds});

  @override
  List<Object?> get props => [mutedChannelIds];
}

/// Lightweight init for background sessions — skips FCM registration.
class NotificationInitBackground extends NotificationEvent {
  final String userId;

  const NotificationInitBackground({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class NotificationChannelSettingChanged extends NotificationEvent {
  final String channelId;
  final String filter;

  const NotificationChannelSettingChanged({
    required this.channelId,
    required this.filter,
  });

  @override
  List<Object?> get props => [channelId, filter];
}
