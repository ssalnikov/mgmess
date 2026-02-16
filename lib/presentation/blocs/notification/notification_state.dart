import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationReady extends NotificationState {
  final String? token;
  final bool enabled;

  const NotificationReady({this.token, this.enabled = true});

  @override
  List<Object?> get props => [token, enabled];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object?> get props => [message];
}
