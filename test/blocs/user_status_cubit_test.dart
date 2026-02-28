import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/core/network/websocket_events.dart';
import 'package:mgmess/domain/repositories/user_repository.dart';
import 'package:mgmess/presentation/blocs/user_status/user_status_cubit.dart';

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
