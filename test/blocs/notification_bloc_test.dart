import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

const _notificationSettings = NotificationSettings(
  authorizationStatus: AuthorizationStatus.authorized,
  alert: AppleNotificationSetting.enabled,
  badge: AppleNotificationSetting.enabled,
  sound: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.disabled,
  carPlay: AppleNotificationSetting.disabled,
  criticalAlert: AppleNotificationSetting.disabled,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.disabled,
  providesAppNotificationSettings: AppleNotificationSetting.disabled,
);

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

void _stubServiceForInit(MockNotificationService s) {
  when(() => s.isInitialized).thenReturn(true);
  when(() => s.requestPermission())
      .thenAnswer((_) async => _notificationSettings);
  when(() => s.getToken()).thenAnswer((_) async => 'fcm_token');
  when(() => s.onTokenRefresh).thenAnswer((_) => const Stream<String>.empty());
}

void main() {
  late MockNotificationRepository mockRepository;
  late MockNotificationService mockService;

  setUp(() {
    mockRepository = MockNotificationRepository();
    mockService = MockNotificationService();
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationBloc', () {
    group('NotificationInit', () {
      blocTest<NotificationBloc, NotificationState>(
        'emits [NotificationReady] when service is initialized',
        build: () {
          _stubServiceForInit(mockService);
          when(() => mockRepository.registerDeviceToken(any()))
              .thenAnswer((_) async => const Right(null));
          return NotificationBloc(
            repository: mockRepository,
            notificationService: mockService,
          );
        },
        act: (bloc) => bloc.add(const NotificationInit(userId: 'user1')),
        expect: () => [
          const NotificationReady(token: 'fcm_token', enabled: true),
        ],
        verify: (_) {
          verify(() => mockRepository.registerDeviceToken('fcm_token'))
              .called(1);
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'emits [NotificationReady(enabled: false)] when service not initialized',
        build: () {
          when(() => mockService.isInitialized).thenReturn(false);
          return NotificationBloc(
            repository: mockRepository,
            notificationService: mockService,
          );
        },
        act: (bloc) => bloc.add(const NotificationInit(userId: 'user1')),
        expect: () => [
          const NotificationReady(enabled: false),
        ],
      );
    });

    group('NotificationWsEvent', () {
      blocTest<NotificationBloc, NotificationState>(
        'shows notification for new post in different channel',
        build: () {
          when(() => mockService.showNotification(
                title: any(named: 'title'),
                body: any(named: 'body'),
                channelId: any(named: 'channelId'),
                postId: any(named: 'postId'),
              )).thenAnswer((_) async {});
          return NotificationBloc(
            repository: mockRepository,
            notificationService: mockService,
          );
        },
        seed: () => const NotificationReady(token: 'tok', enabled: true),
        act: (bloc) {
          bloc.add(NotificationWsEvent(
            wsEvent: _makePostedEvent(),
          ));
        },
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(() => mockService.showNotification(
                title: 'Town Square',
                body: 'john: Hello!',
                channelId: 'ch1',
                postId: any(named: 'postId'),
              )).called(1);
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'does not show notification for own messages',
        build: () {
          _stubServiceForInit(mockService);
          when(() => mockRepository.registerDeviceToken(any()))
              .thenAnswer((_) async => const Right(null));
          return NotificationBloc(
            repository: mockRepository,
            notificationService: mockService,
          );
        },
        act: (bloc) async {
          bloc.add(const NotificationInit(userId: 'user1'));
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
              ));
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'does not show notification for active channel',
        build: () => NotificationBloc(
          repository: mockRepository,
          notificationService: mockService,
        ),
        seed: () => const NotificationReady(token: 'tok', enabled: true),
        act: (bloc) async {
          bloc.add(const NotificationSetActiveChannel(channelId: 'ch1'));
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(NotificationWsEvent(
            wsEvent: _makePostedEvent(channelId: 'ch1'),
          ));
        },
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verifyNever(() => mockService.showNotification(
                title: any(named: 'title'),
                body: any(named: 'body'),
                channelId: any(named: 'channelId'),
                postId: any(named: 'postId'),
              ));
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'does not show notification when disabled',
        build: () => NotificationBloc(
          repository: mockRepository,
          notificationService: mockService,
        ),
        seed: () => const NotificationReady(token: 'tok', enabled: false),
        act: (bloc) {
          bloc.add(NotificationWsEvent(
            wsEvent: _makePostedEvent(),
          ));
        },
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verifyNever(() => mockService.showNotification(
                title: any(named: 'title'),
                body: any(named: 'body'),
                channelId: any(named: 'channelId'),
                postId: any(named: 'postId'),
              ));
        },
      );

      blocTest<NotificationBloc, NotificationState>(
        'ignores non-posted WS events',
        build: () => NotificationBloc(
          repository: mockRepository,
          notificationService: mockService,
        ),
        seed: () => const NotificationReady(token: 'tok', enabled: true),
        act: (bloc) {
          bloc.add(const NotificationWsEvent(
            wsEvent: WsEvent(
              event: WsEventType.typing,
              data: {'channel_id': 'ch1'},
            ),
          ));
        },
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verifyNever(() => mockService.showNotification(
                title: any(named: 'title'),
                body: any(named: 'body'),
                channelId: any(named: 'channelId'),
                postId: any(named: 'postId'),
              ));
        },
      );
    });

    group('NotificationLogout', () {
      blocTest<NotificationBloc, NotificationState>(
        'emits [NotificationInitial] and unregisters device',
        build: () {
          when(() => mockRepository.unregisterDevice())
              .thenAnswer((_) async => const Right(null));
          return NotificationBloc(
            repository: mockRepository,
            notificationService: mockService,
          );
        },
        seed: () => const NotificationReady(token: 'tok', enabled: true),
        act: (bloc) => bloc.add(const NotificationLogout()),
        expect: () => [const NotificationInitial()],
        verify: (_) {
          verify(() => mockRepository.unregisterDevice()).called(1);
        },
      );
    });

    group('NotificationSetActiveChannel / ClearActiveChannel', () {
      blocTest<NotificationBloc, NotificationState>(
        'shows notification after clearing active channel',
        build: () {
          when(() => mockService.showNotification(
                title: any(named: 'title'),
                body: any(named: 'body'),
                channelId: any(named: 'channelId'),
                postId: any(named: 'postId'),
              )).thenAnswer((_) async {});
          return NotificationBloc(
            repository: mockRepository,
            notificationService: mockService,
          );
        },
        seed: () => const NotificationReady(token: 'tok', enabled: true),
        act: (bloc) async {
          bloc.add(const NotificationSetActiveChannel(channelId: 'ch1'));
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(const NotificationClearActiveChannel());
          await Future.delayed(const Duration(milliseconds: 10));
          bloc.add(NotificationWsEvent(
            wsEvent: _makePostedEvent(channelId: 'ch1'),
          ));
        },
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(() => mockService.showNotification(
                title: 'Town Square',
                body: 'john: Hello!',
                channelId: 'ch1',
                postId: any(named: 'postId'),
              )).called(1);
        },
      );
    });
  });
}
