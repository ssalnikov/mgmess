import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/di/session_manager.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/core/notifications/notification_service.dart';
import 'package:mgmess/core/storage/secure_storage.dart';
import 'package:mgmess/domain/entities/server_account.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late SessionManager manager;
  late MockSecureStorage secureStorage;
  late MockNetworkInfo networkInfo;
  late MockNotificationService notificationService;

  final now = DateTime(2026, 3, 25);

  final account1 = ServerAccount(
    id: 'acc1',
    serverUrl: 'https://server1.com',
    displayName: 'Server 1',
    addedAt: now,
    lastActiveAt: now,
  );

  final account2 = ServerAccount(
    id: 'acc2',
    serverUrl: 'https://server2.com',
    displayName: 'Server 2',
    addedAt: now,
    lastActiveAt: now,
  );

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

  group('SessionManager', () {
    test('starts with no sessions', () {
      expect(manager.hasSessions, false);
      expect(manager.activeSession, isNull);
      expect(manager.allSessions, isEmpty);
    });

    test('createSession creates and stores session', () {
      final session = manager.createSession(account1);

      expect(session.accountId, 'acc1');
      expect(session.serverUrl, 'https://server1.com');
      expect(manager.hasSessions, true);
      expect(manager.allSessions.length, 1);
    });

    test('createSession returns existing session for same account', () {
      final session1 = manager.createSession(account1);
      final session2 = manager.createSession(account1);

      expect(identical(session1, session2), true);
      expect(manager.allSessions.length, 1);
    });

    test('switchTo activates session', () {
      manager.createSession(account1);
      manager.createSession(account2);

      manager.switchTo('acc1');
      expect(manager.activeSession?.accountId, 'acc1');

      manager.switchTo('acc2');
      expect(manager.activeSession?.accountId, 'acc2');
    });

    test('removeSession removes and switches active', () async {
      manager.createSession(account1);
      manager.createSession(account2);
      manager.switchTo('acc1');

      await manager.removeSession('acc1');

      expect(manager.allSessions.length, 1);
      expect(manager.activeSession?.accountId, 'acc2');
    });

    test('removeSession clears active when last session removed', () async {
      manager.createSession(account1);
      manager.switchTo('acc1');

      await manager.removeSession('acc1');

      expect(manager.hasSessions, false);
      expect(manager.activeSession, isNull);
    });

    test('dispose removes all sessions', () async {
      manager.createSession(account1);
      manager.createSession(account2);
      manager.switchTo('acc1');

      await manager.dispose();

      expect(manager.hasSessions, false);
      expect(manager.activeSession, isNull);
    });

    test('multiple sessions have independent apiClients', () {
      final session1 = manager.createSession(account1);
      final session2 = manager.createSession(account2);

      expect(session1.apiClient.dio.options.baseUrl,
          'https://server1.com/api/v4');
      expect(session2.apiClient.dio.options.baseUrl,
          'https://server2.com/api/v4');
    });
  });
}
