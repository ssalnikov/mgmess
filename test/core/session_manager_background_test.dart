import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final now = DateTime(2026, 3, 26);

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

  final account3 = ServerAccount(
    id: 'acc3',
    serverUrl: 'https://server3.com',
    addedAt: now,
    lastActiveAt: now,
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
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

  group('backgroundSessions', () {
    test('returns empty list when no sessions', () {
      expect(manager.backgroundSessions, isEmpty);
    });

    test('returns empty list when only active session exists', () {
      manager.createSession(account1);
      manager.switchTo('acc1');
      expect(manager.backgroundSessions, isEmpty);
    });

    test('returns non-active sessions', () {
      manager.createSession(account1);
      manager.createSession(account2);
      manager.createSession(account3);
      manager.switchTo('acc1');

      final bg = manager.backgroundSessions;
      expect(bg.length, 2);
      expect(bg.map((s) => s.accountId), containsAll(['acc2', 'acc3']));
      expect(bg.map((s) => s.accountId), isNot(contains('acc1')));
    });

    test('updates after switchTo', () {
      manager.createSession(account1);
      manager.createSession(account2);
      manager.switchTo('acc1');

      expect(manager.backgroundSessions.length, 1);
      expect(manager.backgroundSessions.first.accountId, 'acc2');

      manager.switchTo('acc2');
      expect(manager.backgroundSessions.length, 1);
      expect(manager.backgroundSessions.first.accountId, 'acc1');
    });
  });

  group('displayName propagation', () {
    test('uses account displayName when available', () {
      final session = manager.createSession(account1);
      expect(session.displayName, 'Server 1');
    });

    test('falls back to host name when displayName is empty', () {
      final session = manager.createSession(account3);
      expect(session.displayName, 'server3.com');
    });
  });

  group('initBackgroundSessions', () {
    test('checks token and userId for background sessions, not active',
        () async {
      when(() => secureStorage.getAccountToken('acc2'))
          .thenAnswer((_) async => 'token2');
      when(() => secureStorage.getAccountToken('acc3'))
          .thenAnswer((_) async => null);
      when(() => secureStorage.getAccountUserId('acc2'))
          .thenAnswer((_) async => 'user2');
      when(() => secureStorage.getAccountUserId('acc3'))
          .thenAnswer((_) async => null);
      // WebSocketClient.connect() calls getTokenFor internally
      when(() => secureStorage.getTokenFor('acc2'))
          .thenAnswer((_) async => 'token2');
      when(() => secureStorage.getTokenFor('acc3'))
          .thenAnswer((_) async => null);

      manager.createSession(account1);
      manager.createSession(account2);
      manager.createSession(account3);
      manager.switchTo('acc1');

      await manager.initBackgroundSessions();

      // Background sessions' tokens and userIds are checked
      verify(() => secureStorage.getAccountToken('acc2'))
          .called(greaterThanOrEqualTo(1));
      verify(() => secureStorage.getAccountToken('acc3')).called(1);
      verify(() => secureStorage.getAccountUserId('acc2')).called(1);
      verify(() => secureStorage.getAccountUserId('acc3')).called(1);
      // Active session token is pre-cached by switchTo, but initBackgroundSessions
      // does not check userId for it
      verifyNever(() => secureStorage.getAccountUserId('acc1'));
    });
  });
}
