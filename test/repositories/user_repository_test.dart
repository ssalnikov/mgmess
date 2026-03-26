import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mgmess/core/error/exceptions.dart';
import 'package:mgmess/core/error/failures.dart';
import 'package:mgmess/data/datasources/local/user_local_datasource.dart';
import 'package:mgmess/data/datasources/remote/user_remote_datasource.dart';
import 'package:mgmess/data/models/user_model.dart';
import 'package:mgmess/data/repositories/user_repository_impl.dart';
import 'package:mgmess/domain/entities/user.dart';

class MockUserRemoteDataSource extends Mock
    implements UserRemoteDataSource {}

class MockUserLocalDataSource extends Mock
    implements UserLocalDataSource {}

void main() {
  late MockUserRemoteDataSource mockRemote;
  late MockUserLocalDataSource mockLocal;
  late UserRepositoryImpl repository;

  setUp(() {
    mockRemote = MockUserRemoteDataSource();
    mockLocal = MockUserLocalDataSource();
    repository = UserRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      baseUrl: 'https://test.example.com/api/v4',
    );
  });

  setUpAll(() {
    registerFallbackValue(<User>[]);
  });

  const testUser = UserModel(
    id: 'user1',
    username: 'testuser',
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
  );

  const testUser2 = UserModel(
    id: 'user2',
    username: 'anotheruser',
    email: 'another@example.com',
  );

  group('UserRepositoryImpl', () {
    group('getUser', () {
      test('returns cached user when available', () async {
        when(() => mockLocal.getUser(any()))
            .thenAnswer((_) async => testUser);

        final result = await repository.getUser('user1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (user) {
            expect(user.id, 'user1');
            expect(user.username, 'testuser');
          },
        );
        verifyNever(() => mockRemote.getUser(any()));
      });

      test('fetches from remote when not in cache', () async {
        when(() => mockLocal.getUser(any()))
            .thenAnswer((_) async => null);
        when(() => mockRemote.getUser(any()))
            .thenAnswer((_) async => testUser);
        when(() => mockLocal.cacheUsers(any()))
            .thenAnswer((_) async {});

        final result = await repository.getUser('user1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (user) => expect(user.id, 'user1'),
        );
        verify(() => mockRemote.getUser('user1')).called(1);
      });

      test('fetches from remote when local throws', () async {
        when(() => mockLocal.getUser(any()))
            .thenThrow(const CacheException(message: 'DB error'));
        when(() => mockRemote.getUser(any()))
            .thenAnswer((_) async => testUser);
        when(() => mockLocal.cacheUsers(any()))
            .thenAnswer((_) async {});

        final result = await repository.getUser('user1');

        expect(result.isRight(), true);
      });

      test('returns ServerFailure when remote fails', () async {
        when(() => mockLocal.getUser(any()))
            .thenAnswer((_) async => null);
        when(() => mockRemote.getUser(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.getUser('user1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getUsersByIds', () {
      test('returns users on success', () async {
        when(() => mockRemote.getUsersByIds(any()))
            .thenAnswer((_) async => [testUser, testUser2]);
        when(() => mockLocal.cacheUsers(any()))
            .thenAnswer((_) async {});

        final result =
            await repository.getUsersByIds(['user1', 'user2']);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (users) => expect(users, hasLength(2)),
        );
      });

      test('returns ServerFailure on exception', () async {
        when(() => mockRemote.getUsersByIds(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.getUsersByIds(['user1']);

        expect(result.isLeft(), true);
      });
    });

    group('updateUser', () {
      test('returns updated user on success', () async {
        when(() => mockRemote.updateUser(any(), any()))
            .thenAnswer((_) async => testUser);
        when(() => mockLocal.cacheUsers(any()))
            .thenAnswer((_) async {});

        final result = await repository.updateUser(
          'user1',
          {'first_name': 'Updated'},
        );

        expect(result.isRight(), true);
      });

      test('returns ServerFailure on exception', () async {
        when(() => mockRemote.updateUser(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result = await repository.updateUser(
          'user1',
          {'first_name': 'Updated'},
        );

        expect(result.isLeft(), true);
      });
    });

    group('uploadUserImage', () {
      test('returns Right(null) on success', () async {
        when(() => mockRemote.uploadUserImage(any(), any()))
            .thenAnswer((_) async {});

        final result =
            await repository.uploadUserImage('user1', '/tmp/img.png');

        expect(result.isRight(), true);
      });

      test('returns ServerFailure on exception', () async {
        when(() => mockRemote.uploadUserImage(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.uploadUserImage('user1', '/tmp/img.png');

        expect(result.isLeft(), true);
      });
    });

    group('autocompleteUsers', () {
      test('returns users on success', () async {
        when(() => mockRemote.autocompleteUsers(
              any(),
              channelId: any(named: 'channelId'),
            )).thenAnswer((_) async => [testUser]);
        when(() => mockLocal.cacheUsers(any()))
            .thenAnswer((_) async {});

        final result = await repository.autocompleteUsers('test');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (users) {
            expect(users, hasLength(1));
            expect(users[0].username, 'testuser');
          },
        );
      });

      test('passes channelId when provided', () async {
        when(() => mockRemote.autocompleteUsers(
              any(),
              channelId: any(named: 'channelId'),
            )).thenAnswer((_) async => [testUser]);
        when(() => mockLocal.cacheUsers(any()))
            .thenAnswer((_) async {});

        await repository.autocompleteUsers('test',
            channelId: 'ch1');

        verify(() => mockRemote.autocompleteUsers(
              'test',
              channelId: 'ch1',
            )).called(1);
      });

      test('returns ServerFailure on exception', () async {
        when(() => mockRemote.autocompleteUsers(
              any(),
              channelId: any(named: 'channelId'),
            )).thenThrow(const ServerException(message: 'Error'));

        final result = await repository.autocompleteUsers('test');

        expect(result.isLeft(), true);
      });
    });

    group('getUserStatuses', () {
      test('returns statuses on success', () async {
        when(() => mockRemote.getUserStatuses(any())).thenAnswer(
          (_) async => (
            statuses: {'user1': 'online', 'user2': 'away'},
            lastActivity: {'user1': 1000, 'user2': 2000},
          ),
        );

        final result =
            await repository.getUserStatuses(['user1', 'user2']);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (data) {
            expect(data.statuses['user1'], 'online');
            expect(data.statuses['user2'], 'away');
            expect(data.lastActivity['user1'], 1000);
          },
        );
      });

      test('returns ServerFailure on exception', () async {
        when(() => mockRemote.getUserStatuses(any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.getUserStatuses(['user1']);

        expect(result.isLeft(), true);
      });
    });

    group('updateUserStatus', () {
      test('returns Right(null) on success', () async {
        when(() => mockRemote.updateUserStatus(any(), any()))
            .thenAnswer((_) async {});

        final result =
            await repository.updateUserStatus('user1', 'dnd');

        expect(result.isRight(), true);
        verify(() => mockRemote.updateUserStatus('user1', 'dnd'))
            .called(1);
      });

      test('returns ServerFailure on exception', () async {
        when(() => mockRemote.updateUserStatus(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        final result =
            await repository.updateUserStatus('user1', 'online');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('getUserImageUrl', () {
      test('returns correct URL format', () {
        final url = repository.getUserImageUrl('user1');
        expect(url, contains('user1'));
        expect(url, contains('image'));
      });
    });
  });
}
