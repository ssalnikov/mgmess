import 'package:equatable/equatable.dart';

enum WsBlocConnectionState { disconnected, connecting, connected }

class WebSocketState extends Equatable {
  final WsBlocConnectionState connectionState;

  const WebSocketState({
    this.connectionState = WsBlocConnectionState.disconnected,
  });

  WebSocketState copyWith({WsBlocConnectionState? connectionState}) {
    return WebSocketState(
      connectionState: connectionState ?? this.connectionState,
    );
  }

  @override
  List<Object?> get props => [connectionState];
}
