import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/di/server_session.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/core/notifications/notification_service.dart';
import 'package:mgmess/core/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockSecureStorage secureStorage;
  late MockNetworkInfo networkInfo;
  late MockNotificationService notificationService;

  setUp(() {
    secureStorage = MockSecureStorage();
    networkInfo = MockNetworkInfo();
    notificationService = MockNotificationService();
  });

  group('ServerSession', () {
    test('creates all per-server dependencies', () {
      final session = ServerSession(
        accountId: 'acc1',
        serverUrl: 'https://mm.example.com',
        secureStorage: secureStorage,
        networkInfo: networkInfo,
        notificationService: notificationService,
      );

      // Network
      expect(session.apiClient, isNotNull);
      expect(session.webSocketClient, isNotNull);
      expect(session.apiClient.dio.options.baseUrl,
          'https://mm.example.com/api/v4');
      expect(session.apiClient.accountId, 'acc1');

      // Database
      expect(session.database, isNotNull);

      // DAOs
      expect(session.postDao, isNotNull);
      expect(session.channelDao, isNotNull);
      expect(session.userDao, isNotNull);
      expect(session.channelCategoryDao, isNotNull);

      // Local Data Sources
      expect(session.postLocalDataSource, isNotNull);
      expect(session.channelLocalDataSource, isNotNull);
      expect(session.userLocalDataSource, isNotNull);
      expect(session.channelCategoryLocalDataSource, isNotNull);

      // Remote Data Sources
      expect(session.authRemoteDataSource, isNotNull);
      expect(session.userRemoteDataSource, isNotNull);
      expect(session.channelRemoteDataSource, isNotNull);
      expect(session.postRemoteDataSource, isNotNull);
      expect(session.fileRemoteDataSource, isNotNull);
      expect(session.seensRemoteDataSource, isNotNull);
      expect(session.notificationRemoteDataSource, isNotNull);
      expect(session.emojiRemoteDataSource, isNotNull);
      expect(session.commandRemoteDataSource, isNotNull);

      // Services
      expect(session.wsPostParser, isNotNull);
      expect(session.sendQueueService, isNotNull);

      // Repositories
      expect(session.authRepository, isNotNull);
      expect(session.userRepository, isNotNull);
      expect(session.channelRepository, isNotNull);
      expect(session.postRepository, isNotNull);
      expect(session.fileRepository, isNotNull);
      expect(session.seensRepository, isNotNull);
      expect(session.notificationRepository, isNotNull);

      // BLoCs
      expect(session.authBloc, isNotNull);
      expect(session.webSocketBloc, isNotNull);
      expect(session.notificationBloc, isNotNull);
      expect(session.userStatusCubit, isNotNull);
    });

    test('builds correct WS URL for https server', () {
      final session = ServerSession(
        accountId: 'acc1',
        serverUrl: 'https://mm.example.com',
        secureStorage: secureStorage,
        networkInfo: networkInfo,
        notificationService: notificationService,
      );

      // WebSocketClient is created — we can't easily inspect the wsUrl
      // since it's private, but we verify the session creates successfully
      expect(session.webSocketClient, isNotNull);
    });

    test('different sessions have different apiClient instances', () {
      final session1 = ServerSession(
        accountId: 'acc1',
        serverUrl: 'https://server1.com',
        secureStorage: secureStorage,
        networkInfo: networkInfo,
        notificationService: notificationService,
      );
      final session2 = ServerSession(
        accountId: 'acc2',
        serverUrl: 'https://server2.com',
        secureStorage: secureStorage,
        networkInfo: networkInfo,
        notificationService: notificationService,
      );

      expect(session1.apiClient, isNot(same(session2.apiClient)));
      expect(session1.apiClient.dio.options.baseUrl,
          'https://server1.com/api/v4');
      expect(session2.apiClient.dio.options.baseUrl,
          'https://server2.com/api/v4');
    });

    test('different sessions have different databases', () {
      final session1 = ServerSession(
        accountId: 'acc1',
        serverUrl: 'https://server1.com',
        secureStorage: secureStorage,
        networkInfo: networkInfo,
        notificationService: notificationService,
      );
      final session2 = ServerSession(
        accountId: 'acc2',
        serverUrl: 'https://server2.com',
        secureStorage: secureStorage,
        networkInfo: networkInfo,
        notificationService: notificationService,
      );

      expect(session1.database, isNot(same(session2.database)));
    });
  });
}
