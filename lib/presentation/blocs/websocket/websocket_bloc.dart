import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/websocket_client.dart';
import '../../../core/network/websocket_events.dart';
import 'websocket_event.dart';
import 'websocket_state.dart';

class WebSocketBloc extends Bloc<WebSocketEvent, WebSocketState> {
  final WebSocketClient _webSocketClient;
  StreamSubscription<WsConnectionState>? _stateSub;
  StreamSubscription<WsEvent>? _eventSub;

  final _wsEventController = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get wsEvents => _wsEventController.stream;

  WebSocketBloc({required WebSocketClient webSocketClient})
      : _webSocketClient = webSocketClient,
        super(const WebSocketState()) {
    on<WebSocketConnect>(_onConnect);
    on<WebSocketDisconnect>(_onDisconnect);
    on<WebSocketConnectionChanged>(_onConnectionChanged);
  }

  Future<void> _onConnect(
    WebSocketConnect event,
    Emitter<WebSocketState> emit,
  ) async {
    emit(state.copyWith(
      connectionState: WsBlocConnectionState.connecting,
    ));

    _stateSub?.cancel();
    _stateSub = _webSocketClient.stateChanges.listen((wsState) {
      switch (wsState) {
        case WsConnectionState.connected:
          add(const WebSocketConnectionChanged(isConnected: true));
        case WsConnectionState.disconnected:
          add(const WebSocketConnectionChanged(isConnected: false));
        case WsConnectionState.connecting:
          break;
      }
    });

    _eventSub?.cancel();
    _eventSub = _webSocketClient.events.listen((wsEvent) {
      _wsEventController.add(wsEvent);
    });

    await _webSocketClient.connect();
  }

  Future<void> _onDisconnect(
    WebSocketDisconnect event,
    Emitter<WebSocketState> emit,
  ) async {
    _webSocketClient.disconnect();
    emit(state.copyWith(
      connectionState: WsBlocConnectionState.disconnected,
    ));
  }

  void _onConnectionChanged(
    WebSocketConnectionChanged event,
    Emitter<WebSocketState> emit,
  ) {
    emit(state.copyWith(
      connectionState: event.isConnected
          ? WsBlocConnectionState.connected
          : WsBlocConnectionState.disconnected,
    ));
  }

  void sendTyping(String channelId) {
    _webSocketClient.sendTyping(channelId);
  }

  @override
  Future<void> close() {
    _stateSub?.cancel();
    _eventSub?.cancel();
    _wsEventController.close();
    return super.close();
  }
}
