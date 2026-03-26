import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/network/websocket_events.dart';
import 'package:mgmess/core/notifications/notification_service.dart';
import 'package:mgmess/domain/repositories/notification_repository.dart';
import 'package:mgmess/presentation/blocs/notification/notification_bloc.dart';
import 'package:mgmess/presentation/blocs/notification/notification_event.dart';
import 'package:mgmess/presentation/blocs/notification/notification_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockNotificationService extends Mock implements NotificationService {}

WsEvent _makePostedEvent({
  String senderId = 'other_user',
  String channelId = 'ch1',
  String message = 'Hello!',
  String senderName = 'john',
  String channelDisplayName = 'Town Square',
}) {
  final postJson = jsonEncode({
    'id': 'post_123',
    'user_id': senderId,
    'channel_id': channelId,
    'message': message,
  });
  return WsEvent(
    event: WsEventType.posted,
    data: {
      'post': postJson,
      'sender_name': senderName,
      'channel_display_name': channelDisplayName,
      'channel_type': 'O',
    },
    broadcast: {'channel_id': channelId},
  );
}

void main() {
  group('NotificationTapPayload', () {
    test('stores all fields', () {
      const payload = NotificationTapPayload(
        channelId: 'ch1',
        postId: 'post1',
        accountId: 'acc1',
        serverUrl: 'https://example.com',
      );

      expect(payload.channelId, 'ch1');
      expect(payload.postId, 'post1');
      expect(payload.accountId, 'acc1');
      expect(payload.serverUrl, 'https://example.com');
    });

    test('allows null fields', () {
      const payload = NotificationTapPayload();

      expect(payload.channelId, isNull);
      expect(payload.postId, isNull);
      expect(payload.accountId, isNull);
      expect(payload.serverUrl, isNull);
    });
  });

  group('NotificationBloc passes accountId to showNotification', () {
    late MockNotificationRepository mockRepository;
    late MockNotificationService mockService;

    setUp(() {
      mockRepository = MockNotificationRepository();
      mockService = MockNotificationService();
      SharedPreferences.setMockInitialValues({});
    });

    blocTest<NotificationBloc, NotificationState>(
      'passes accountId when set',
      build: () {
        when(() => mockService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              channelId: any(named: 'channelId'),
              postId: any(named: 'postId'),
              accountId: any(named: 'accountId'),
            )).thenAnswer((_) async {});
        return NotificationBloc(
          repository: mockRepository,
          notificationService: mockService,
          accountId: 'my_account',
        );
      },
      seed: () => const NotificationReady(token: 'tok', enabled: true),
      act: (bloc) => bloc.add(NotificationWsEvent(
        wsEvent: _makePostedEvent(),
      )),
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => mockService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              channelId: 'ch1',
              postId: any(named: 'postId'),
              accountId: 'my_account',
            )).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'passes null accountId when not set',
      build: () {
        when(() => mockService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              channelId: any(named: 'channelId'),
              postId: any(named: 'postId'),
              accountId: any(named: 'accountId'),
            )).thenAnswer((_) async {});
        return NotificationBloc(
          repository: mockRepository,
          notificationService: mockService,
        );
      },
      seed: () => const NotificationReady(token: 'tok', enabled: true),
      act: (bloc) => bloc.add(NotificationWsEvent(
        wsEvent: _makePostedEvent(),
      )),
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => mockService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              channelId: 'ch1',
              postId: any(named: 'postId'),
              accountId: null,
            )).called(1);
      },
    );
  });
}
