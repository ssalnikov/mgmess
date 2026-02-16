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
