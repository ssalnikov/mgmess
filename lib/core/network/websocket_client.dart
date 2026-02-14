import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'websocket_events.dart';

enum WsConnectionState { disconnected, connecting, connected }

class WebSocketClient {
  final SecureStorage _secureStorage;
  final _logger = Logger(printer: SimplePrinter());

  WebSocketChannel? _channel;
  final _eventController = StreamController<WsEvent>.broadcast();
  final _stateController =
      StreamController<WsConnectionState>.broadcast();

  WsConnectionState _state = WsConnectionState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  int _seq = 0;

  WebSocketClient({required SecureStorage secureStorage})
      : _secureStorage = secureStorage;

  Stream<WsEvent> get events => _eventController.stream;
  Stream<WsConnectionState> get stateChanges => _stateController.stream;
  WsConnectionState get state => _state;

  Future<void> connect() async {
    if (_state == WsConnectionState.connecting ||
        _state == WsConnectionState.connected) {
      return;
    }

    _setState(WsConnectionState.connecting);
    final token = await _secureStorage.getToken();
    if (token == null) {
      _logger.e('WS: No auth token, cannot connect');
      _setState(WsConnectionState.disconnected);
      return;
    }

    try {
      final wsUrl = Uri.parse(AppConfig.wsUrl);
      _channel = WebSocketChannel.connect(wsUrl);
      await _channel!.ready;

      // Send auth challenge
      _send({
        'seq': ++_seq,
        'action': 'authentication_challenge',
        'data': {'token': token},
      });

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _logger.e('WS: Connection failed: $e');
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _channel?.sink.close();
    _channel = null;
    _setState(WsConnectionState.disconnected);
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void sendTyping(String channelId) {
    _send({
      'action': 'user_typing',
      'seq': ++_seq,
      'data': {'channel_id': channelId},
    });
  }

  void _onMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final event = WsEvent.fromJson(json);

      if (event.event == WsEventType.hello) {
        _logger.i('WS: Connected (hello received)');
        _setState(WsConnectionState.connected);
        _reconnectAttempts = 0;
        return;
      }

      if (event.event.isNotEmpty) {
        _eventController.add(event);
      }
    } catch (e) {
      _logger.e('WS: Failed to parse message: $e');
    }
  }

  void _onError(dynamic error) {
    _logger.e('WS: Error: $error');
    _setState(WsConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _onDone() {
    _logger.w('WS: Connection closed');
    _setState(WsConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = _getReconnectDelay();
    _logger.i('WS: Reconnecting in ${delay.inSeconds}s '
        '(attempt ${_reconnectAttempts + 1})');
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  Duration _getReconnectDelay() {
    // Exponential backoff: 1s → 2s → 4s → 8s → 16s → 30s (max)
    final seconds = min(pow(2, _reconnectAttempts).toInt(), 30);
    return Duration(seconds: seconds);
  }

  void _setState(WsConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}
