import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/core/network/websocket_events.dart';
import 'package:mgmess/domain/repositories/user_repository.dart';
import 'package:mgmess/presentation/blocs/user_status/user_status_cubit.dart';

import 'package:mgmess/domain/entities/user.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockUserRepository = MockUserRepository();
  });

  group('UserStatusCubit', () {
    test('initial state has empty statuses', () {
      final cubit = UserStatusCubit(userRepository: mockUserRepository);
      expect(cubit.state.statuses, isEmpty);
      cubit.close();
    });

    group('fetchStatuses', () {
      blocTest<UserStatusCubit, UserStatusState>(
        'updates statuses on success',
        build: () {
          when(() => mockUserRepository.getUserStatuses(any()))
              .thenAnswer((_) async => const Right({
                    'user1': 'online',
                    'user2': 'away',
                  }));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.fetchStatuses(['user1', 'user2']),
        expect: () => [
          const UserStatusState(statuses: {
            'user1': 'online',
            'user2': 'away',
          }),
        ],
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'does not emit on failure',
        build: () {
          when(() => mockUserRepository.getUserStatuses(any()))
              .thenAnswer((_) async =>
                  const Left(ServerFailure(message: 'Error')));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.fetchStatuses(['user1']),
        expect: () => [],
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'does nothing for empty list',
        build: () =>
            UserStatusCubit(userRepository: mockUserRepository),
        act: (cubit) => cubit.fetchStatuses([]),
        expect: () => [],
        verify: (_) {
          verifyNever(
              () => mockUserRepository.getUserStatuses(any()));
        },
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'merges new statuses with existing ones',
        seed: () =>
            const UserStatusState(statuses: {'user1': 'online'}),
        build: () {
          when(() => mockUserRepository.getUserStatuses(any()))
              .thenAnswer((_) async =>
                  const Right({'user2': 'dnd'}));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.fetchStatuses(['user2']),
        expect: () => [
          const UserStatusState(statuses: {
            'user1': 'online',
            'user2': 'dnd',
          }),
        ],
      );
    });

    group('subscribeToWs', () {
      test('updates status on status_change event', () async {
        final wsController = StreamController<WsEvent>.broadcast();
        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        cubit.subscribeToWs(wsController.stream);

        wsController.add(const WsEvent(
          event: 'status_change',
          data: {'user_id': 'user1', 'status': 'online'},
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.statuses['user1'], 'online');

        await cubit.close();
        await wsController.close();
      });

      test('ignores non-status_change events', () async {
        final wsController = StreamController<WsEvent>.broadcast();
        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        cubit.subscribeToWs(wsController.stream);

        wsController.add(const WsEvent(
          event: 'posted',
          data: {'user_id': 'user1', 'status': 'online'},
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.statuses, isEmpty);

        await cubit.close();
        await wsController.close();
      });

      test('ignores status_change with missing fields', () async {
        final wsController = StreamController<WsEvent>.broadcast();
        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        cubit.subscribeToWs(wsController.stream);

        wsController.add(const WsEvent(
          event: 'status_change',
          data: {'user_id': 'user1'},
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.statuses, isEmpty);

        await cubit.close();
        await wsController.close();
      });

      test('refreshes all statuses on hello (WS reconnect)', () async {
        when(() => mockUserRepository.getUserStatuses(any()))
            .thenAnswer((_) async => const Right({
                  'user1': 'away',
                  'user2': 'offline',
                }));

        final wsController = StreamController<WsEvent>.broadcast();
        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        // Pre-populate stale statuses
        cubit.emit(const UserStatusState(statuses: {
          'user1': 'online',
          'user2': 'online',
        }));

        cubit.subscribeToWs(wsController.stream);

        // Simulate WS reconnect
        wsController.add(const WsEvent(
          event: 'hello',
          data: {},
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockUserRepository.getUserStatuses(any())).called(1);
        expect(cubit.state.statuses['user1'], 'away');
        expect(cubit.state.statuses['user2'], 'offline');

        await cubit.close();
        await wsController.close();
      });

      test('hello with no cached statuses does not call API', () async {
        final wsController = StreamController<WsEvent>.broadcast();
        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        cubit.subscribeToWs(wsController.stream);

        wsController.add(const WsEvent(
          event: 'hello',
          data: {},
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => mockUserRepository.getUserStatuses(any()));

        await cubit.close();
        await wsController.close();
      });

      test('overwrites existing status for same user', () async {
        final wsController = StreamController<WsEvent>.broadcast();
        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        cubit.subscribeToWs(wsController.stream);

        wsController.add(const WsEvent(
          event: 'status_change',
          data: {'user_id': 'user1', 'status': 'online'},
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        wsController.add(const WsEvent(
          event: 'status_change',
          data: {'user_id': 'user1', 'status': 'away'},
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.statuses['user1'], 'away');

        await cubit.close();
        await wsController.close();
      });
    });

    group('updateStatus', () {
      blocTest<UserStatusCubit, UserStatusState>(
        'optimistically updates status on success',
        seed: () => const UserStatusState(statuses: {'user1': 'online'}),
        build: () {
          when(() => mockUserRepository.updateUserStatus(any(), any()))
              .thenAnswer((_) async => const Right(null));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.updateStatus('user1', 'dnd'),
        expect: () => [
          const UserStatusState(statuses: {'user1': 'dnd'}),
        ],
        verify: (_) {
          verify(() => mockUserRepository.updateUserStatus('user1', 'dnd'))
              .called(1);
        },
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'rolls back status on error',
        seed: () => const UserStatusState(statuses: {'user1': 'online'}),
        build: () {
          when(() => mockUserRepository.updateUserStatus(any(), any()))
              .thenAnswer((_) async =>
                  const Left(ServerFailure(message: 'Error')));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.updateStatus('user1', 'dnd'),
        expect: () => [
          const UserStatusState(statuses: {'user1': 'dnd'}),
          const UserStatusState(statuses: {'user1': 'online'}),
        ],
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'removes status on rollback when no previous value',
        build: () {
          when(() => mockUserRepository.updateUserStatus(any(), any()))
              .thenAnswer((_) async =>
                  const Left(ServerFailure(message: 'Error')));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.updateStatus('user1', 'away'),
        expect: () => [
          const UserStatusState(statuses: {'user1': 'away'}),
          const UserStatusState(statuses: {}),
        ],
      );
    });

    group('custom status', () {
      test('initial state has empty customStatuses', () {
        final cubit = UserStatusCubit(userRepository: mockUserRepository);
        expect(cubit.state.customStatuses, isEmpty);
        cubit.close();
      });

      blocTest<UserStatusCubit, UserStatusState>(
        'setCustomStatusFromUser sets custom status',
        build: () =>
            UserStatusCubit(userRepository: mockUserRepository),
        act: (cubit) => cubit.setCustomStatusFromUser(const User(
          id: 'user1',
          username: 'test',
          customStatusEmoji: 'palm_tree',
          customStatusText: 'On vacation',
        )),
        expect: () => [
          const UserStatusState(customStatuses: {
            'user1': CustomStatus(emoji: 'palm_tree', text: 'On vacation'),
          }),
        ],
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'setCustomStatusFromUser removes custom status when empty',
        seed: () => const UserStatusState(customStatuses: {
          'user1': CustomStatus(emoji: 'palm_tree', text: 'On vacation'),
        }),
        build: () =>
            UserStatusCubit(userRepository: mockUserRepository),
        act: (cubit) => cubit.setCustomStatusFromUser(const User(
          id: 'user1',
          username: 'test',
        )),
        expect: () => [
          const UserStatusState(customStatuses: {}),
        ],
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'updateCustomStatus optimistically updates on success',
        build: () {
          when(() => mockUserRepository.updateCustomStatus(
                any(),
                emoji: any(named: 'emoji'),
                text: any(named: 'text'),
              )).thenAnswer((_) async => const Right(null));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.updateCustomStatus(
          'user1',
          emoji: 'rocket',
          text: 'Launching',
        ),
        expect: () => [
          const UserStatusState(customStatuses: {
            'user1': CustomStatus(emoji: 'rocket', text: 'Launching'),
          }),
        ],
        verify: (_) {
          verify(() => mockUserRepository.updateCustomStatus(
                'user1',
                emoji: 'rocket',
                text: 'Launching',
              )).called(1);
        },
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'updateCustomStatus rolls back on error',
        seed: () => const UserStatusState(customStatuses: {
          'user1': CustomStatus(emoji: 'palm_tree', text: 'On vacation'),
        }),
        build: () {
          when(() => mockUserRepository.updateCustomStatus(
                any(),
                emoji: any(named: 'emoji'),
                text: any(named: 'text'),
              )).thenAnswer((_) async =>
              const Left(ServerFailure(message: 'Error')));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.updateCustomStatus(
          'user1',
          emoji: 'rocket',
          text: 'Launching',
        ),
        expect: () => [
          const UserStatusState(customStatuses: {
            'user1': CustomStatus(emoji: 'rocket', text: 'Launching'),
          }),
          const UserStatusState(customStatuses: {
            'user1': CustomStatus(emoji: 'palm_tree', text: 'On vacation'),
          }),
        ],
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'clearCustomStatus removes custom status on success',
        seed: () => const UserStatusState(customStatuses: {
          'user1': CustomStatus(emoji: 'rocket', text: 'Launching'),
        }),
        build: () {
          when(() => mockUserRepository.deleteCustomStatus(any()))
              .thenAnswer((_) async => const Right(null));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.clearCustomStatus('user1'),
        expect: () => [
          const UserStatusState(customStatuses: {}),
        ],
        verify: (_) {
          verify(() => mockUserRepository.deleteCustomStatus('user1'))
              .called(1);
        },
      );

      blocTest<UserStatusCubit, UserStatusState>(
        'clearCustomStatus rolls back on error',
        seed: () => const UserStatusState(customStatuses: {
          'user1': CustomStatus(emoji: 'rocket', text: 'Launching'),
        }),
        build: () {
          when(() => mockUserRepository.deleteCustomStatus(any()))
              .thenAnswer((_) async =>
                  const Left(ServerFailure(message: 'Error')));
          return UserStatusCubit(userRepository: mockUserRepository);
        },
        act: (cubit) => cubit.clearCustomStatus('user1'),
        expect: () => [
          const UserStatusState(customStatuses: {}),
          const UserStatusState(customStatuses: {
            'user1': CustomStatus(emoji: 'rocket', text: 'Launching'),
          }),
        ],
      );

      test('WS user_updated event updates custom status', () async {
        final wsController = StreamController<WsEvent>.broadcast();
        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        cubit.subscribeToWs(wsController.stream);

        wsController.add(const WsEvent(
          event: 'user_updated',
          data: {
            'user': {
              'id': 'user1',
              'username': 'test',
              'props': {
                'customStatus': {
                  'emoji': 'coffee',
                  'text': 'Having lunch',
                },
              },
            },
          },
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.customStatuses['user1'],
            const CustomStatus(emoji: 'coffee', text: 'Having lunch'));

        await cubit.close();
        await wsController.close();
      });

      test('WS user_updated removes custom status when empty', () async {
        final wsController = StreamController<WsEvent>.broadcast();
        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        // Set initial custom status
        cubit.setCustomStatusFromUser(const User(
          id: 'user1',
          username: 'test',
          customStatusEmoji: 'coffee',
          customStatusText: 'Having lunch',
        ));

        cubit.subscribeToWs(wsController.stream);

        wsController.add(const WsEvent(
          event: 'user_updated',
          data: {
            'user': {
              'id': 'user1',
              'username': 'test',
            },
          },
        ));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(cubit.state.customStatuses['user1'], isNull);

        await cubit.close();
        await wsController.close();
      });
    });

    group('requestStatus', () {
      test('batches requests and fetches after delay', () async {
        when(() => mockUserRepository.getUserStatuses(any()))
            .thenAnswer((_) async => const Right({
                  'user1': 'online',
                  'user2': 'away',
                }));

        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        cubit.requestStatus('user1');
        cubit.requestStatus('user2');

        // Before timer fires
        verifyNever(() => mockUserRepository.getUserStatuses(any()));

        // Wait for batch timer (100ms) + processing
        await Future.delayed(const Duration(milliseconds: 200));

        verify(() => mockUserRepository.getUserStatuses(any()))
            .called(1);
        expect(cubit.state.statuses['user1'], 'online');
        expect(cubit.state.statuses['user2'], 'away');

        await cubit.close();
      });

      test('skips already known statuses', () async {
        when(() => mockUserRepository.getUserStatuses(any()))
            .thenAnswer(
                (_) async => const Right({'user2': 'online'}));

        final cubit =
            UserStatusCubit(userRepository: mockUserRepository);

        // Manually set a status
        cubit.emit(const UserStatusState(
            statuses: {'user1': 'online'}));

        cubit.requestStatus('user1'); // already known
        cubit.requestStatus('user2'); // new

        await Future.delayed(const Duration(milliseconds: 200));

        // Should only fetch user2
        final captured = verify(
          () => mockUserRepository.getUserStatuses(captureAny()),
        ).captured;
        expect(captured.last, ['user2']);

        await cubit.close();
      });
    });
  });
}
