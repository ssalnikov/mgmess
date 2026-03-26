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

  setUp(() {
    secureStorage = MockSecureStorage();
    networkInfo = MockNetworkInfo();
    notificationService = MockNotificationService();
    manager = SessionManager(
      secureStorage: secureStorage,
      networkInfo: networkInfo,
      notificationService: notificationService,
    );
  });

  group('OAuth routing', () {
    test('consumePendingOAuth returns null when no OAuth in progress', () {
      expect(manager.consumePendingOAuth(), isNull);
    });

    test('startOAuth + consumePendingOAuth returns the account id', () {
      manager.startOAuth('acc1');
      expect(manager.consumePendingOAuth(), 'acc1');
    });

    test('consumePendingOAuth clears the pending id', () {
      manager.startOAuth('acc1');
      manager.consumePendingOAuth();
      expect(manager.consumePendingOAuth(), isNull);
    });

    test('startOAuth overwrites previous pending id', () {
      manager.startOAuth('acc1');
      manager.startOAuth('acc2');
      expect(manager.consumePendingOAuth(), 'acc2');
    });

    test('pending OAuth id is independent of active session', () {
      manager.createSession(account1);
      manager.createSession(account2);
      manager.switchTo('acc1');

      // OAuth started for acc2 while acc1 is active.
      manager.startOAuth('acc2');

      expect(manager.activeSession?.accountId, 'acc1');
      expect(manager.consumePendingOAuth(), 'acc2');
    });

    test('removeSession does not clear pending OAuth for other account',
        () async {
      manager.createSession(account1);
      manager.createSession(account2);
      manager.switchTo('acc1');
      manager.startOAuth('acc2');

      await manager.removeSession('acc1');

      expect(manager.consumePendingOAuth(), 'acc2');
    });

    test('dispose does not clear pending OAuth (no sessions left)', () async {
      manager.createSession(account1);
      manager.switchTo('acc1');
      manager.startOAuth('acc1');

      await manager.dispose();

      // Pending id is still set (consumed by App's deep-link handler).
      expect(manager.consumePendingOAuth(), 'acc1');
    });
  });
}
