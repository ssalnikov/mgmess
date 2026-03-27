import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/di/session_manager.dart';
import 'package:mgmess/core/network/network_info.dart';
import 'package:mgmess/core/notifications/notification_service.dart';
import 'package:mgmess/core/storage/secure_storage.dart';
import 'package:mgmess/domain/entities/server_account.dart';
import 'package:mgmess/domain/repositories/server_account_repository.dart';
import 'package:mgmess/presentation/blocs/server/server_list_cubit.dart';

class MockServerAccountRepository extends Mock
    implements ServerAccountRepository {}

class MockSecureStorage extends Mock implements SecureStorage {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockServerAccountRepository accountRepo;
  late SessionManager sessionManager;
  late MockSecureStorage secureStorage;

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
    accountRepo = MockServerAccountRepository();
    secureStorage = MockSecureStorage();
    sessionManager = SessionManager(
      secureStorage: secureStorage,
      networkInfo: MockNetworkInfo(),
      notificationService: MockNotificationService(),
    );

    when(() => secureStorage.getAccountToken(any()))
        .thenAnswer((_) async => null);
  });

  setUpAll(() {
    registerFallbackValue(account1);
  });

  ServerListCubit buildCubit() => ServerListCubit(
        accountRepo: accountRepo,
        sessionManager: sessionManager,
      );

  group('ServerListCubit', () {
    blocTest<ServerListCubit, ServerListState>(
      'load emits accounts and active id',
      build: () {
        when(() => accountRepo.getAll()).thenAnswer((_) async => [account1]);
        when(() => accountRepo.getActive())
            .thenAnswer((_) async => account1);
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        ServerListState(
          accounts: [account1],
          activeAccountId: 'acc1',
        ),
      ],
    );

    blocTest<ServerListCubit, ServerListState>(
      'load with no accounts emits empty state',
      build: () {
        when(() => accountRepo.getAll()).thenAnswer((_) async => []);
        when(() => accountRepo.getActive()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const ServerListState(accounts: [], activeAccountId: null),
      ],
    );

    blocTest<ServerListCubit, ServerListState>(
      'switchServer changes active and creates session',
      seed: () => ServerListState(
        accounts: [account1, account2],
        activeAccountId: 'acc1',
      ),
      build: () {
        // Pre-create sessions so switchTo works
        sessionManager.createSession(account1);
        sessionManager.switchTo(account1.id);

        when(() => accountRepo.setActive('acc2')).thenAnswer((_) async {});
        when(() => accountRepo.update(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.switchServer('acc2'),
      verify: (cubit) {
        expect(cubit.state.activeAccountId, 'acc2');
        expect(sessionManager.activeSession?.accountId, 'acc2');
        verify(() => accountRepo.setActive('acc2')).called(1);
        verify(() => accountRepo.update(any())).called(1);
      },
    );

    blocTest<ServerListCubit, ServerListState>(
      'switchServer to same account does nothing',
      seed: () => ServerListState(
        accounts: [account1],
        activeAccountId: 'acc1',
      ),
      build: buildCubit,
      act: (cubit) => cubit.switchServer('acc1'),
      expect: () => [],
    );

    blocTest<ServerListCubit, ServerListState>(
      'addServer adds account and switches to it',
      seed: () => ServerListState(
        accounts: [account1],
        activeAccountId: 'acc1',
      ),
      build: () {
        when(() => accountRepo.add(account2)).thenAnswer((_) async {});
        when(() => accountRepo.setActive('acc2')).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.addServer(account2),
      verify: (cubit) {
        expect(cubit.state.accounts.length, 2);
        expect(cubit.state.activeAccountId, 'acc2');
        expect(sessionManager.activeSession?.accountId, 'acc2');
      },
    );

    blocTest<ServerListCubit, ServerListState>(
      'removeServer removes account and switches to remaining',
      seed: () => ServerListState(
        accounts: [account1, account2],
        activeAccountId: 'acc1',
      ),
      build: () {
        // Create both sessions
        sessionManager.createSession(account1);
        sessionManager.createSession(account2);
        sessionManager.switchTo(account1.id);

        when(() => accountRepo.remove('acc1')).thenAnswer((_) async {});
        when(() => accountRepo.setActive('acc2')).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.removeServer('acc1'),
      verify: (cubit) {
        expect(cubit.state.accounts.length, 1);
        expect(cubit.state.accounts.first.id, 'acc2');
        // SessionManager should have switched to acc2
        expect(cubit.state.activeAccountId, 'acc2');
      },
    );

    blocTest<ServerListCubit, ServerListState>(
      'removeServer last account leaves empty state',
      seed: () => ServerListState(
        accounts: [account1],
        activeAccountId: 'acc1',
      ),
      build: () {
        sessionManager.createSession(account1);
        sessionManager.switchTo(account1.id);

        when(() => accountRepo.remove('acc1')).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.removeServer('acc1'),
      verify: (cubit) {
        expect(cubit.state.accounts, isEmpty);
        expect(cubit.state.activeAccountId, isNull);
      },
    );

    test('initial state is empty', () {
      final cubit = buildCubit();
      expect(cubit.state, const ServerListState());
      cubit.close();
    });
  });
}
