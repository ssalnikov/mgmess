import 'dart:async';

import 'package:mgmess/core/network/websocket_client.dart';
import 'package:mgmess/core/network/websocket_events.dart';

import 'fake_secure_storage.dart';

/// FakeWebSocketClient для интеграционных тестов.
/// Не подключается к реальному серверу, позволяет симулировать WS-события.
class FakeWebSocketClient extends WebSocketClient {
  final _eventController = StreamController<WsEvent>.broadcast();
  final _stateController = StreamController<WsConnectionState>.broadcast();
  WsConnectionState _state = WsConnectionState.disconnected;

  FakeWebSocketClient() : super(secureStorage: FakeSecureStorage());

  @override
  Stream<WsEvent> get events => _eventController.stream;

  @override
  Stream<WsConnectionState> get stateChanges => _stateController.stream;

  @override
  WsConnectionState get state => _state;

  @override
  Future<void> connect() async {
    _state = WsConnectionState.connected;
    _stateController.add(WsConnectionState.connected);
  }

  @override
  void disconnect() {
    _state = WsConnectionState.disconnected;
    _stateController.add(WsConnectionState.disconnected);
  }

  @override
  void sendTyping(String channelId) {
    // no-op
  }

  /// Симулирует WS-событие в тестах.
  void simulateEvent(WsEvent event) {
    _eventController.add(event);
  }

  @override
  void dispose() {
    _eventController.close();
    _stateController.close();
  }
}
