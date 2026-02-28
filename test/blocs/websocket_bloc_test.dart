import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/network/websocket_client.dart';
import 'package:mgmess/core/network/websocket_events.dart';
import 'package:mgmess/presentation/blocs/websocket/websocket_bloc.dart';
import 'package:mgmess/presentation/blocs/websocket/websocket_event.dart';
import 'package:mgmess/presentation/blocs/websocket/websocket_state.dart';

class MockWebSocketClient extends Mock implements WebSocketClient {}

void main() {
  late MockWebSocketClient mockWsClient;
  late StreamController<WsConnectionState> stateController;
  late StreamController<WsEvent> eventController;

  setUp(() {
    mockWsClient = MockWebSocketClient();
    stateController = StreamController<WsConnectionState>.broadcast();
    eventController = StreamController<WsEvent>.broadcast();

    when(() => mockWsClient.stateChanges)
        .thenAnswer((_) => stateController.stream);
    when(() => mockWsClient.events)
        .thenAnswer((_) => eventController.stream);
    when(() => mockWsClient.connect()).thenAnswer((_) async {});
    when(() => mockWsClient.disconnect()).thenReturn(null);
    when(() => mockWsClient.sendTyping(any())).thenReturn(null);
  });

  tearDown(() {
    stateController.close();
    eventController.close();
  });

  group('WebSocketBloc', () {
    group('WebSocketConnect', () {
      blocTest<WebSocketBloc, WebSocketState>(
        'emits connecting and calls connect()',
        build: () => WebSocketBloc(webSocketClient: mockWsClient),
        act: (bloc) => bloc.add(const WebSocketConnect()),
        expect: () => [
          const WebSocketState(
            connectionState: WsBlocConnectionState.connecting,
          ),
        ],
        verify: (_) {
          verify(() => mockWsClient.connect()).called(1);
        },
      );

      blocTest<WebSocketBloc, WebSocketState>(
        'emits connecting then connected when WS state becomes connected',
        build: () => WebSocketBloc(webSocketClient: mockWsClient),
        act: (bloc) async {
          bloc.add(const WebSocketConnect());
          await Future.delayed(Duration.zero);
          stateController.add(WsConnectionState.connected);
        },
        wait: const Duration(milliseconds: 50),
        expect: () => [
          const WebSocketState(
            connectionState: WsBlocConnectionState.connecting,
          ),
          const WebSocketState(
            connectionState: WsBlocConnectionState.connected,
          ),
        ],
      );

      blocTest<WebSocketBloc, WebSocketState>(
        'emits connecting then disconnected when WS state becomes disconnected',
        build: () => WebSocketBloc(webSocketClient: mockWsClient),
        act: (bloc) async {
          bloc.add(const WebSocketConnect());
          await Future.delayed(Duration.zero);
          stateController.add(WsConnectionState.disconnected);
        },
        wait: const Duration(milliseconds: 50),
        expect: () => [
          const WebSocketState(
            connectionState: WsBlocConnectionState.connecting,
          ),
          const WebSocketState(
            connectionState: WsBlocConnectionState.disconnected,
          ),
        ],
      );
    });

    group('WebSocketConnectionChanged', () {
      blocTest<WebSocketBloc, WebSocketState>(
        'emits connected when isConnected is true',
        build: () => WebSocketBloc(webSocketClient: mockWsClient),
        act: (bloc) => bloc
            .add(const WebSocketConnectionChanged(isConnected: true)),
        expect: () => [
          const WebSocketState(
            connectionState: WsBlocConnectionState.connected,
          ),
        ],
      );

      blocTest<WebSocketBloc, WebSocketState>(
        'emits disconnected when isConnected is false',
        build: () => WebSocketBloc(webSocketClient: mockWsClient),
        act: (bloc) => bloc
            .add(const WebSocketConnectionChanged(isConnected: false)),
        expect: () => [
          const WebSocketState(
            connectionState: WsBlocConnectionState.disconnected,
          ),
        ],
      );
    });

    group('WebSocketDisconnect', () {
      blocTest<WebSocketBloc, WebSocketState>(
        'calls disconnect() and emits disconnected',
        build: () => WebSocketBloc(webSocketClient: mockWsClient),
        act: (bloc) => bloc.add(const WebSocketDisconnect()),
        expect: () => [
          const WebSocketState(
            connectionState: WsBlocConnectionState.disconnected,
          ),
        ],
        verify: (_) {
          verify(() => mockWsClient.disconnect()).called(1);
        },
      );
    });

    group('wsEvents stream', () {
      test('forwards WS events to wsEvents stream', () async {
        final bloc = WebSocketBloc(webSocketClient: mockWsClient);
        final receivedEvents = <WsEvent>[];

        bloc.wsEvents.listen(receivedEvents.add);

        bloc.add(const WebSocketConnect());
        await Future.delayed(Duration.zero);

        const testEvent = WsEvent(
          event: 'posted',
          data: {'post': 'test'},
          broadcast: {'channel_id': 'ch1'},
          seq: 1,
        );
        eventController.add(testEvent);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first.event, 'posted');
        expect(receivedEvents.first.seq, 1);

        await bloc.close();
      });
    });

    group('sendTyping', () {
      test('delegates to WebSocketClient', () {
        final bloc = WebSocketBloc(webSocketClient: mockWsClient);

        bloc.sendTyping('channel123');

        verify(() => mockWsClient.sendTyping('channel123')).called(1);

        bloc.close();
      });
    });

    group('close', () {
      test('cancels subscriptions and closes wsEvent controller', () async {
        final bloc = WebSocketBloc(webSocketClient: mockWsClient);

        bloc.add(const WebSocketConnect());
        await Future.delayed(Duration.zero);

        await bloc.close();

        // After close, no more events should be forwarded
        final events = <WsEvent>[];
        bloc.wsEvents.listen(events.add);
        eventController.add(const WsEvent(
          event: 'posted',
          data: {},
          seq: 99,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        expect(events, isEmpty);
      });
    });
  });
}
