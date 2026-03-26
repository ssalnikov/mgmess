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
  String channelType = 'O',
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
      'channel_type': channelType,
    },
    broadcast: {'channel_id': channelId},
  );
}

void main() {
  late MockNotificationRepository mockRepository;
  late MockNotificationService mockService;

  setUp(() {
    mockRepository = MockNotificationRepository();
    mockService = MockNotificationService();
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationInitBackground', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationReady without FCM registration',
      build: () => NotificationBloc(
        repository: mockRepository,
        notificationService: mockService,
        accountId: 'acc1',
      ),
      act: (bloc) =>
          bloc.add(const NotificationInitBackground(userId: 'user1')),
      expect: () => [const NotificationReady(enabled: true)],
      verify: (_) {
        // Must NOT call FCM methods
        verifyNever(() => mockService.requestPermission());
        verifyNever(() => mockService.getToken());
        verifyNever(
            () => mockRepository.registerDeviceToken(any()));
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'respects global notification_enabled=false preference',
      setUp: () {
        SharedPreferences.setMockInitialValues({
          'notification_enabled': false,
        });
      },
      build: () => NotificationBloc(
        repository: mockRepository,
        notificationService: mockService,
        accountId: 'acc1',
      ),
      act: (bloc) =>
          bloc.add(const NotificationInitBackground(userId: 'user1')),
      expect: () => [const NotificationReady(enabled: false)],
    );

    blocTest<NotificationBloc, NotificationState>(
      'loads per-channel notification filters',
      setUp: () {
        SharedPreferences.setMockInitialValues({
          'channel_notification_acc1_ch_muted': 'none',
          'channel_notification_acc1_ch_mentions': 'mentions',
        });
      },
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
          accountId: 'acc1',
        );
      },
      act: (bloc) async {
        bloc.add(const NotificationInitBackground(userId: 'user1'));
        await Future.delayed(const Duration(milliseconds: 50));
        // Send to muted channel — should be suppressed
        bloc.add(NotificationWsEvent(
          wsEvent: _makePostedEvent(channelId: 'ch_muted'),
        ));
      },
      wait: const Duration(milliseconds: 200),
      verify: (_) {
        verifyNever(() => mockService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              channelId: 'ch_muted',
              postId: any(named: 'postId'),
              accountId: any(named: 'accountId'),
            ));
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'filters own messages after background init',
      build: () => NotificationBloc(
        repository: mockRepository,
        notificationService: mockService,
        accountId: 'acc1',
      ),
      act: (bloc) async {
        bloc.add(const NotificationInitBackground(userId: 'user1'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(NotificationWsEvent(
          wsEvent: _makePostedEvent(senderId: 'user1'),
        ));
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verifyNever(() => mockService.showNotification(
              title: any(named: 'title'),
              body: any(named: 'body'),
              channelId: any(named: 'channelId'),
              postId: any(named: 'postId'),
              accountId: any(named: 'accountId'),
            ));
      },
    );
  });

  group('serverDisplayName prefix', () {
    blocTest<NotificationBloc, NotificationState>(
      'prefixes notification title with [serverName] when set',
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
          serverDisplayName: 'Corp Server',
        );
      },
      seed: () => const NotificationReady(token: 'tok', enabled: true),
      act: (bloc) => bloc.add(NotificationWsEvent(
        wsEvent: _makePostedEvent(),
      )),
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => mockService.showNotification(
              title: '[Corp Server] Town Square',
              body: 'john: Hello!',
              channelId: 'ch1',
              postId: any(named: 'postId'),
              accountId: any(named: 'accountId'),
            )).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'no prefix when serverDisplayName is null',
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
              title: 'Town Square',
              body: 'john: Hello!',
              channelId: 'ch1',
              postId: any(named: 'postId'),
              accountId: any(named: 'accountId'),
            )).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'no prefix when serverDisplayName is empty',
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
          serverDisplayName: '',
        );
      },
      seed: () => const NotificationReady(token: 'tok', enabled: true),
      act: (bloc) => bloc.add(NotificationWsEvent(
        wsEvent: _makePostedEvent(),
      )),
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => mockService.showNotification(
              title: 'Town Square',
              body: 'john: Hello!',
              channelId: 'ch1',
              postId: any(named: 'postId'),
              accountId: any(named: 'accountId'),
            )).called(1);
      },
    );
  });
}
