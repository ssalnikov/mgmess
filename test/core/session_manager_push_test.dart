import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/di/server_session.dart';
import 'package:mgmess/core/di/session_manager.dart';
import 'package:mgmess/core/network/api_client.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/core/network/websocket_client.dart';
import 'package:mgmess/core/notifications/notification_service.dart';
import 'package:mgmess/core/storage/secure_storage.dart';
import 'package:mgmess/data/datasources/remote/emoji_remote_datasource.dart';
import 'package:mgmess/domain/repositories/auth_repository.dart';
import 'package:mgmess/domain/repositories/channel_repository.dart';
import 'package:mgmess/domain/repositories/file_repository.dart';
import 'package:mgmess/domain/repositories/notification_repository.dart';
import 'package:mgmess/domain/repositories/post_repository.dart';
import 'package:mgmess/domain/repositories/seens_repository.dart';
import 'package:mgmess/domain/repositories/user_repository.dart';
import 'package:mgmess/domain/services/ws_post_parser.dart';
import 'package:mgmess/presentation/blocs/auth/auth_bloc.dart';
import 'package:mgmess/presentation/blocs/notification/notification_bloc.dart';
import 'package:mgmess/presentation/blocs/user_status/user_status_cubit.dart';
import 'package:mgmess/presentation/blocs/websocket/websocket_bloc.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockApiClient extends Mock implements ApiClient {}

class MockWebSocketClient extends Mock implements WebSocketClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockChannelRepository extends Mock implements ChannelRepository {}

class MockPostRepository extends Mock implements PostRepository {}

class MockFileRepository extends Mock implements FileRepository {}

class MockSeensRepository extends Mock implements SeensRepository {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockWebSocketBloc extends Mock implements WebSocketBloc {}

class MockNotificationBloc extends Mock implements NotificationBloc {}

class MockUserStatusCubit extends Mock implements UserStatusCubit {}

class MockWsPostParser extends Mock implements WsPostParser {}

class MockEmojiRemoteDataSource extends Mock
    implements EmojiRemoteDataSource {}

ServerSession _makeTestSession({
  required String accountId,
  required String serverUrl,
  required SecureStorage secureStorage,
  required NotificationRepository notificationRepository,
  String displayName = '',
}) {
  return ServerSession.forTest(
    accountId: accountId,
    serverUrl: serverUrl,
    displayName: displayName,
    baseUrl: '$serverUrl/api/v4',
    oauthUrl: '$serverUrl/oauth',
    secureStorage: secureStorage,
    apiClient: MockApiClient(),
    webSocketClient: MockWebSocketClient(),
    authRepository: MockAuthRepository(),
    userRepository: MockUserRepository(),
    channelRepository: MockChannelRepository(),
    postRepository: MockPostRepository(),
    fileRepository: MockFileRepository(),
    seensRepository: MockSeensRepository(),
    notificationRepository: notificationRepository,
    authBloc: MockAuthBloc(),
    webSocketBloc: MockWebSocketBloc(),
    notificationBloc: MockNotificationBloc(),
    userStatusCubit: MockUserStatusCubit(),
    wsPostParser: MockWsPostParser(),
    emojiRemoteDataSource: MockEmojiRemoteDataSource(),
  );
}

void main() {
  late SessionManager manager;
  late MockSecureStorage secureStorage;
  late MockNetworkInfo networkInfo;
  late MockNotificationService notificationService;

  setUp(() {
    secureStorage = MockSecureStorage();
    networkInfo = MockNetworkInfo();
    notificationService = MockNotificationService();
    manager = SessionManager(
      secureStorage: secureStorage,
      networkInfo: networkInfo,
      notificationService: notificationService,
    );

    when(() => secureStorage.getAccountToken(any()))
        .thenAnswer((_) async => null);
  });

  group('registerFcmTokenOnAllSessions', () {
    late MockNotificationRepository notifRepo1;
    late MockNotificationRepository notifRepo2;

    setUp(() {
      notifRepo1 = MockNotificationRepository();
      notifRepo2 = MockNotificationRepository();
    });

    test('registers token on sessions with stored auth token', () async {
      when(() => secureStorage.getAccountToken('acc1'))
          .thenAnswer((_) async => 'token1');
      when(() => secureStorage.getAccountToken('acc2'))
          .thenAnswer((_) async => 'token2');
      when(() => notifRepo1.registerDeviceToken(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => notifRepo2.registerDeviceToken(any()))
          .thenAnswer((_) async => const Right(null));

      final session1 = _makeTestSession(
        accountId: 'acc1',
        serverUrl: 'https://server1.com',
        secureStorage: secureStorage,
        notificationRepository: notifRepo1,
      );
      final session2 = _makeTestSession(
        accountId: 'acc2',
        serverUrl: 'https://server2.com',
        secureStorage: secureStorage,
        notificationRepository: notifRepo2,
      );

      manager.setTestSession(session1);
      manager.setTestSession(session2);
      manager.switchTo('acc1');

      await manager.registerFcmTokenOnAllSessions('fcm_tok');

      verify(() => notifRepo1.registerDeviceToken('fcm_tok')).called(1);
      verify(() => notifRepo2.registerDeviceToken('fcm_tok')).called(1);
    });

    test('skips sessions without stored auth token', () async {
      when(() => secureStorage.getAccountToken('acc1'))
          .thenAnswer((_) async => 'token1');
      when(() => secureStorage.getAccountToken('acc2'))
          .thenAnswer((_) async => null);
      when(() => notifRepo1.registerDeviceToken(any()))
          .thenAnswer((_) async => const Right(null));

      final session1 = _makeTestSession(
        accountId: 'acc1',
        serverUrl: 'https://server1.com',
        secureStorage: secureStorage,
        notificationRepository: notifRepo1,
      );
      final session2 = _makeTestSession(
        accountId: 'acc2',
        serverUrl: 'https://server2.com',
        secureStorage: secureStorage,
        notificationRepository: notifRepo2,
      );

      manager.setTestSession(session1);
      manager.setTestSession(session2);
      manager.switchTo('acc1');

      await manager.registerFcmTokenOnAllSessions('fcm_tok');

      verify(() => notifRepo1.registerDeviceToken('fcm_tok')).called(1);
      verifyNever(() => notifRepo2.registerDeviceToken(any()));
    });

    test('does not throw when registration fails on a session', () async {
      when(() => secureStorage.getAccountToken('acc1'))
          .thenAnswer((_) async => 'token1');
      when(() => secureStorage.getAccountToken('acc2'))
          .thenAnswer((_) async => 'token2');
      when(() => notifRepo1.registerDeviceToken(any()))
          .thenThrow(Exception('network error'));
      when(() => notifRepo2.registerDeviceToken(any()))
          .thenAnswer((_) async => const Right(null));

      final session1 = _makeTestSession(
        accountId: 'acc1',
        serverUrl: 'https://server1.com',
        secureStorage: secureStorage,
        notificationRepository: notifRepo1,
      );
      final session2 = _makeTestSession(
        accountId: 'acc2',
        serverUrl: 'https://server2.com',
        secureStorage: secureStorage,
        notificationRepository: notifRepo2,
      );

      manager.setTestSession(session1);
      manager.setTestSession(session2);
      manager.switchTo('acc1');

      // Should not throw — errors are caught and logged.
      await expectLater(
        manager.registerFcmTokenOnAllSessions('fcm_tok'),
        completes,
      );

      // acc2 should still be registered despite acc1 failure.
      verify(() => notifRepo2.registerDeviceToken('fcm_tok')).called(1);
    });

    test('handles empty sessions map', () async {
      await expectLater(
        manager.registerFcmTokenOnAllSessions('fcm_tok'),
        completes,
      );
    });
  });

  group('findSessionByServerUrl', () {
    test('finds session by exact URL', () {
      final session1 = _makeTestSession(
        accountId: 'acc1',
        serverUrl: 'https://server1.com',
        secureStorage: secureStorage,
        notificationRepository: MockNotificationRepository(),
      );
      final session2 = _makeTestSession(
        accountId: 'acc2',
        serverUrl: 'https://server2.com',
        secureStorage: secureStorage,
        notificationRepository: MockNotificationRepository(),
      );

      manager.setTestSession(session1);
      manager.setTestSession(session2);
      manager.switchTo('acc1');

      final found = manager.findSessionByServerUrl('https://server2.com');
      expect(found, isNotNull);
      expect(found!.accountId, 'acc2');
    });

    test('finds session ignoring trailing slash', () {
      final session = _makeTestSession(
        accountId: 'acc1',
        serverUrl: 'https://server1.com',
        secureStorage: secureStorage,
        notificationRepository: MockNotificationRepository(),
      );
      manager.setTestSession(session);

      final found = manager.findSessionByServerUrl('https://server1.com/');
      expect(found, isNotNull);
      expect(found!.accountId, 'acc1');
    });

    test('returns null for unknown URL', () {
      final session = _makeTestSession(
        accountId: 'acc1',
        serverUrl: 'https://server1.com',
        secureStorage: secureStorage,
        notificationRepository: MockNotificationRepository(),
      );
      manager.setTestSession(session);

      final found = manager.findSessionByServerUrl('https://unknown.com');
      expect(found, isNull);
    });

    test('returns null when no sessions exist', () {
      final found = manager.findSessionByServerUrl('https://server1.com');
      expect(found, isNull);
    });

    test('finds active session by URL', () {
      final session1 = _makeTestSession(
        accountId: 'acc1',
        serverUrl: 'https://server1.com',
        secureStorage: secureStorage,
        notificationRepository: MockNotificationRepository(),
      );
      final session2 = _makeTestSession(
        accountId: 'acc2',
        serverUrl: 'https://server2.com',
        secureStorage: secureStorage,
        notificationRepository: MockNotificationRepository(),
      );

      manager.setTestSession(session1);
      manager.setTestSession(session2);
      manager.switchTo('acc1');

      final found = manager.findSessionByServerUrl('https://server1.com');
      expect(found, isNotNull);
      expect(found!.accountId, 'acc1');
    });
  });
}
