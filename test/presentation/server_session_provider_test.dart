import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/di/server_session.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/core/notifications/notification_service.dart';
import 'package:mgmess/core/storage/secure_storage.dart';
import 'package:mgmess/presentation/widgets/server_session_provider.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockNotificationService extends Mock implements NotificationService {}

ServerSession _createSession({String accountId = 'acc1'}) {
  return ServerSession(
    accountId: accountId,
    serverUrl: 'https://mm.example.com',
    secureStorage: MockSecureStorage(),
    networkInfo: MockNetworkInfo(),
    notificationService: MockNotificationService(),
  );
}

void main() {
  group('ServerSessionProvider', () {
    testWidgets('provides session to descendants via of()', (tester) async {
      final session = _createSession();
      ServerSession? captured;

      await tester.pumpWidget(
        ServerSessionProvider(
          session: session,
          child: Builder(
            builder: (context) {
              captured = ServerSessionProvider.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, same(session));
    });

    testWidgets('context.serverSession extension works', (tester) async {
      final session = _createSession();
      ServerSession? captured;

      await tester.pumpWidget(
        ServerSessionProvider(
          session: session,
          child: Builder(
            builder: (context) {
              captured = context.serverSession;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, same(session));
    });

    testWidgets('updateShouldNotify returns true for different sessions',
        (tester) async {
      final session1 = _createSession(accountId: 'acc1');
      final session2 = _createSession(accountId: 'acc2');

      final provider1 = ServerSessionProvider(
        session: session1,
        child: const SizedBox(),
      );
      final provider2 = ServerSessionProvider(
        session: session2,
        child: const SizedBox(),
      );

      expect(provider2.updateShouldNotify(provider1), isTrue);
    });

    testWidgets('updateShouldNotify returns false for same session',
        (tester) async {
      final session = _createSession();

      final provider1 = ServerSessionProvider(
        session: session,
        child: const SizedBox(),
      );
      final provider2 = ServerSessionProvider(
        session: session,
        child: const SizedBox(),
      );

      expect(provider2.updateShouldNotify(provider1), isFalse);
    });

    testWidgets('rebuilds descendants when session changes', (tester) async {
      final session1 = _createSession(accountId: 'acc1');
      final session2 = _createSession(accountId: 'acc2');
      final captured = <String>[];

      late StateSetter setState;
      var currentSession = session1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setter) {
            setState = setter;
            return ServerSessionProvider(
              session: currentSession,
              child: Builder(
                builder: (context) {
                  captured.add(context.serverSession.accountId);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      );

      expect(captured, ['acc1']);

      setState(() => currentSession = session2);
      await tester.pump();

      expect(captured, ['acc1', 'acc2']);
    });
  });

  group('ServerSession properties', () {
    test('baseUrl is computed from serverUrl', () {
      final session = _createSession();
      expect(session.baseUrl, 'https://mm.example.com/api/v4');
    });

    test('oauthUrl is computed from serverUrl', () {
      final session = _createSession();
      expect(
        session.oauthUrl,
        contains('https://mm.example.com/oauth/gitlab/mobile_login'),
      );
      expect(session.oauthUrl, contains('redirect_to=mmauth://'));
    });

    test('getAuthToken delegates to secureStorage', () async {
      final storage = MockSecureStorage();
      when(() => storage.getAccountToken('acc1'))
          .thenAnswer((_) async => 'test-token');

      final session = ServerSession(
        accountId: 'acc1',
        serverUrl: 'https://mm.example.com',
        secureStorage: storage,
        networkInfo: MockNetworkInfo(),
        notificationService: MockNotificationService(),
      );

      expect(await session.getAuthToken(), 'test-token');
      verify(() => storage.getAccountToken('acc1')).called(1);
    });
  });
}
