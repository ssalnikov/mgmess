import 'package:equatable/equatable.dart';

abstract class WebSocketEvent extends Equatable {
  const WebSocketEvent();

  @override
  List<Object?> get props => [];
}

class WebSocketConnect extends WebSocketEvent {
  const WebSocketConnect();
}

class WebSocketDisconnect extends WebSocketEvent {
  const WebSocketDisconnect();
}

class WebSocketConnectionChanged extends WebSocketEvent {
  final bool isConnected;

  const WebSocketConnectionChanged({required this.isConnected});

  @override
  List<Object?> get props => [isConnected];
}
